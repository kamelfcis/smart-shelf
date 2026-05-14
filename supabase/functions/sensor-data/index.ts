// Supabase Edge Function: sensor-data
// Receives weight readings from ESP8266 and updates the database

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const WEIGHT_DROP_THRESHOLD = 10.0  // grams — triggers "item removed"
const SENSOR_OFFLINE_MINUTES = 5

interface SensorReading {
  slot: number
  weight_g: number
}

interface SensorPayload {
  sensor_id: string
  readings: SensorReading[]
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const body: SensorPayload = await req.json()
    const { sensor_id, readings } = body

    if (!sensor_id || !readings?.length) {
      return new Response(
        JSON.stringify({ error: 'Missing sensor_id or readings' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 1. Find shelf by sensor_id
    const { data: shelf, error: shelfErr } = await supabase
      .from('shelves')
      .select('id, user_id')
      .eq('sensor_id', sensor_id)
      .maybeSingle()

    if (shelfErr || !shelf) {
      return new Response(
        JSON.stringify({ error: 'Shelf not found for sensor_id: ' + sensor_id }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 2. Update shelves.last_ping and is_online
    await supabase
      .from('shelves')
      .update({ is_online: true, last_ping: new Date().toISOString() })
      .eq('id', shelf.id)

    const notifications: object[] = []

    // 3. Process each reading slot
    for (const reading of readings) {
      // Find item by shelf_id + slot_number
      const { data: item } = await supabase
        .from('items')
        .select('id, name, current_weight, unit_weight_g, tare_weight_g, min_threshold, current_qty')
        .eq('shelf_id', shelf.id)
        .eq('slot_number', reading.slot)
        .eq('is_active', true)
        .maybeSingle()

      if (!item) continue

      const prevWeight = item.current_weight as number
      const newWeight = reading.weight_g
      const weightDrop = prevWeight - newWeight

      // 4. Update item current_weight
      await supabase
        .from('items')
        .update({ current_weight: newWeight })
        .eq('id', item.id)

      // 5. Insert weight log
      const unitW = item.unit_weight_g as number
      const tareW = item.tare_weight_g as number
      const newQty = Math.max(0, Math.floor((newWeight - tareW) / unitW))

      await supabase.from('item_logs').insert({
        item_id: item.id,
        weight_g: newWeight,
        qty: newQty,
      })

      // 6. Check: item removed (sudden drop > threshold)
      if (weightDrop > WEIGHT_DROP_THRESHOLD && newWeight < tareW + unitW) {
        notifications.push({
          user_id: shelf.user_id,
          shelf_id: shelf.id,
          item_id: item.id,
          type: 'item_removed',
          title: `Item removed: ${item.name}`,
          body: `Weight dropped from ${prevWeight.toFixed(1)}g to ${newWeight.toFixed(1)}g`,
        })
      }

      // 7. Check: low stock
      const minThreshold = item.min_threshold as number
      if (newQty > 0 && newQty <= minThreshold) {
        notifications.push({
          user_id: shelf.user_id,
          shelf_id: shelf.id,
          item_id: item.id,
          type: 'low_stock',
          title: `Low stock: ${item.name}`,
          body: `Only ${newQty} unit${newQty !== 1 ? 's' : ''} remaining (threshold: ${minThreshold})`,
        })
      }

      // 8. Check: empty
      if (newQty === 0 && (item.current_qty as number) > 0) {
        notifications.push({
          user_id: shelf.user_id,
          shelf_id: shelf.id,
          item_id: item.id,
          type: 'low_stock',
          title: `Out of stock: ${item.name}`,
          body: `${item.name} is now empty`,
        })
      }
    }

    // 9. Bulk insert notifications
    if (notifications.length > 0) {
      await supabase.from('notifications').insert(notifications)
    }

    return new Response(
      JSON.stringify({
        ok: true,
        shelf_id: shelf.id,
        readings_processed: readings.length,
        notifications_created: notifications.length,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
