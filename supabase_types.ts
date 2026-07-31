export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      app_versions: {
        Row: {
          download_url: string
          id: number
          is_mandatory: boolean | null
          latest_version_code: number
          latest_version_name: string
          platform: string
          release_notes: string | null
        }
        Insert: {
          download_url: string
          id?: number
          is_mandatory?: boolean | null
          latest_version_code: number
          latest_version_name: string
          platform: string
          release_notes?: string | null
        }
        Update: {
          download_url?: string
          id?: number
          is_mandatory?: boolean | null
          latest_version_code?: number
          latest_version_name?: string
          platform?: string
          release_notes?: string | null
        }
        Relationships: []
      }
      daily_boiler_log: {
        Row: {
          authorized_by: string | null
          created_at: string | null
          final_remarks: string | null
          id: string
          kitchen_id: string
          log_date: string
          prepared_by: string | null
          status: boolean | null
          updated_at: string | null
          verified_by: string | null
        }
        Insert: {
          authorized_by?: string | null
          created_at?: string | null
          final_remarks?: string | null
          id?: string
          kitchen_id: string
          log_date: string
          prepared_by?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Update: {
          authorized_by?: string | null
          created_at?: string | null
          final_remarks?: string | null
          id?: string
          kitchen_id?: string
          log_date?: string
          prepared_by?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_boiler_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      daily_boiler_log_detail: {
        Row: {
          air_pressure: number | null
          blowdown_pit_level: string | null
          blowdown_water_hardness: string | null
          blowdown_water_ph: string | null
          blowdown_water_tds: string | null
          boiler_end_time: string | null
          boiler_start_time: string | null
          briquettes_closing_stock_1: number | null
          briquettes_closing_stock_2: number | null
          briquettes_consumption_1: number | null
          briquettes_consumption_2: number | null
          briquettes_opening_stock_1: number | null
          briquettes_opening_stock_2: number | null
          condenset_closing_time: string | null
          condenset_opening_time: string | null
          created_at: string | null
          feed_water_hardness: string | null
          feed_water_ph: string | null
          feed_water_tds: string | null
          id: string
          log_id: string
          main_valve_close_time: string | null
          main_valve_open_time: string | null
          operator_1_name: string | null
          operator_1_sign: string | null
          operator_2_name: string | null
          operator_2_sign: string | null
          operator_3_name: string | null
          operator_3_sign: string | null
          operator_4_name: string | null
          operator_4_sign: string | null
          recovery: number | null
          total_running_hours: number | null
          updated_at: string | null
        }
        Insert: {
          air_pressure?: number | null
          blowdown_pit_level?: string | null
          blowdown_water_hardness?: string | null
          blowdown_water_ph?: string | null
          blowdown_water_tds?: string | null
          boiler_end_time?: string | null
          boiler_start_time?: string | null
          briquettes_closing_stock_1?: number | null
          briquettes_closing_stock_2?: number | null
          briquettes_consumption_1?: number | null
          briquettes_consumption_2?: number | null
          briquettes_opening_stock_1?: number | null
          briquettes_opening_stock_2?: number | null
          condenset_closing_time?: string | null
          condenset_opening_time?: string | null
          created_at?: string | null
          feed_water_hardness?: string | null
          feed_water_ph?: string | null
          feed_water_tds?: string | null
          id?: string
          log_id: string
          main_valve_close_time?: string | null
          main_valve_open_time?: string | null
          operator_1_name?: string | null
          operator_1_sign?: string | null
          operator_2_name?: string | null
          operator_2_sign?: string | null
          operator_3_name?: string | null
          operator_3_sign?: string | null
          operator_4_name?: string | null
          operator_4_sign?: string | null
          recovery?: number | null
          total_running_hours?: number | null
          updated_at?: string | null
        }
        Update: {
          air_pressure?: number | null
          blowdown_pit_level?: string | null
          blowdown_water_hardness?: string | null
          blowdown_water_ph?: string | null
          blowdown_water_tds?: string | null
          boiler_end_time?: string | null
          boiler_start_time?: string | null
          briquettes_closing_stock_1?: number | null
          briquettes_closing_stock_2?: number | null
          briquettes_consumption_1?: number | null
          briquettes_consumption_2?: number | null
          briquettes_opening_stock_1?: number | null
          briquettes_opening_stock_2?: number | null
          condenset_closing_time?: string | null
          condenset_opening_time?: string | null
          created_at?: string | null
          feed_water_hardness?: string | null
          feed_water_ph?: string | null
          feed_water_tds?: string | null
          id?: string
          log_id?: string
          main_valve_close_time?: string | null
          main_valve_open_time?: string | null
          operator_1_name?: string | null
          operator_1_sign?: string | null
          operator_2_name?: string | null
          operator_2_sign?: string | null
          operator_3_name?: string | null
          operator_3_sign?: string | null
          operator_4_name?: string | null
          operator_4_sign?: string | null
          recovery?: number | null
          total_running_hours?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_boiler_log_detail_log_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "daily_boiler_log"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_log_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["log_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_1_name_fkey"
            columns: ["operator_1_name"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_1_name_fkey"
            columns: ["operator_1_name"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_2_name_fkey"
            columns: ["operator_2_name"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_2_name_fkey"
            columns: ["operator_2_name"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_3_name_fkey"
            columns: ["operator_3_name"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_3_name_fkey"
            columns: ["operator_3_name"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_4_name_fkey"
            columns: ["operator_4_name"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_detail_operator_4_name_fkey"
            columns: ["operator_4_name"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      daily_boiler_log_entry: {
        Row: {
          aph_il: number | null
          aph_ol: number | null
          created_at: string | null
          drum_level: number | null
          entry_time: string | null
          feed_tank_level: number | null
          id: string
          log_id: string
          sequence_no: number | null
          steam_pressure: number | null
          updated_at: string | null
        }
        Insert: {
          aph_il?: number | null
          aph_ol?: number | null
          created_at?: string | null
          drum_level?: number | null
          entry_time?: string | null
          feed_tank_level?: number | null
          id?: string
          log_id: string
          sequence_no?: number | null
          steam_pressure?: number | null
          updated_at?: string | null
        }
        Update: {
          aph_il?: number | null
          aph_ol?: number | null
          created_at?: string | null
          drum_level?: number | null
          entry_time?: string | null
          feed_tank_level?: number | null
          id?: string
          log_id?: string
          sequence_no?: number | null
          steam_pressure?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_boiler_log_entry_log_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "daily_boiler_log"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_boiler_log_entry_log_fkey"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["log_id"]
          },
        ]
      }
      daily_electrical_log: {
        Row: {
          authorized_by: string | null
          created_at: string | null
          daily_kvah_consumption: number | null
          daily_kwh_consumption: number | null
          id: string
          kitchen_id: string
          kvah_closing: number | null
          kvah_opening: number | null
          kwh_closing: number
          kwh_opening: number
          log_date: string
          prepared_by: string | null
          status: boolean | null
          updated_at: string | null
          verified_by: string | null
        }
        Insert: {
          authorized_by?: string | null
          created_at?: string | null
          daily_kvah_consumption?: number | null
          daily_kwh_consumption?: number | null
          id?: string
          kitchen_id: string
          kvah_closing?: number | null
          kvah_opening?: number | null
          kwh_closing?: number
          kwh_opening?: number
          log_date: string
          prepared_by?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Update: {
          authorized_by?: string | null
          created_at?: string | null
          daily_kvah_consumption?: number | null
          daily_kwh_consumption?: number | null
          id?: string
          kitchen_id?: string
          kvah_closing?: number | null
          kvah_opening?: number | null
          kwh_closing?: number
          kwh_opening?: number
          log_date?: string
          prepared_by?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_electrical_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_electrical_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_electrical_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_electrical_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_electrical_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_electrical_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      daily_ro_checklist_detail: {
        Row: {
          created_at: string | null
          expected_condition: string | null
          id: string
          is_checked: boolean | null
          log_id: string
          procedure_step: string
          remarks: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          expected_condition?: string | null
          id?: string
          is_checked?: boolean | null
          log_id: string
          procedure_step: string
          remarks?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          expected_condition?: string | null
          id?: string
          is_checked?: boolean | null
          log_id?: string
          procedure_step?: string
          remarks?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_ro_checklist_detail_procedure_step_fkey"
            columns: ["procedure_step"]
            isOneToOne: false
            referencedRelation: "m_ro_checklist_template"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_ro_log"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "daily_ro_checklist_log"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_ro_log"
            columns: ["log_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["log_id"]
          },
        ]
      }
      daily_ro_checklist_log: {
        Row: {
          authorized_by: string | null
          created_at: string | null
          feed_water: number | null
          id: string
          kitchen_id: string
          log_date: string
          prepared_by: string | null
          product_water: number | null
          reject_water: number | null
          status: boolean | null
          updated_at: string | null
          verified_by: string | null
        }
        Insert: {
          authorized_by?: string | null
          created_at?: string | null
          feed_water?: number | null
          id?: string
          kitchen_id: string
          log_date: string
          prepared_by?: string | null
          product_water?: number | null
          reject_water?: number | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Update: {
          authorized_by?: string | null
          created_at?: string | null
          feed_water?: number | null
          id?: string
          kitchen_id?: string
          log_date?: string
          prepared_by?: string | null
          product_water?: number | null
          reject_water?: number | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_ro_checklist_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_ro_checklist_log_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      dg_set_logbook: {
        Row: {
          battery_voltage: number | null
          coolant_temperature: number | null
          created_at: string | null
          dg_frequency: number | null
          diesel_consumption: number | null
          diesel_fill: number | null
          diesel_stock: number | null
          engine_oil_pressure: number | null
          engine_oil_temperature: number | null
          id: string
          is_verified: boolean | null
          kitchen_id: string | null
          log_date: string
          remarks: string | null
          signature: string | null
          total_kwh: number | null
          total_running_hours: number | null
          updated_at: string | null
        }
        Insert: {
          battery_voltage?: number | null
          coolant_temperature?: number | null
          created_at?: string | null
          dg_frequency?: number | null
          diesel_consumption?: number | null
          diesel_fill?: number | null
          diesel_stock?: number | null
          engine_oil_pressure?: number | null
          engine_oil_temperature?: number | null
          id?: string
          is_verified?: boolean | null
          kitchen_id?: string | null
          log_date: string
          remarks?: string | null
          signature?: string | null
          total_kwh?: number | null
          total_running_hours?: number | null
          updated_at?: string | null
        }
        Update: {
          battery_voltage?: number | null
          coolant_temperature?: number | null
          created_at?: string | null
          dg_frequency?: number | null
          diesel_consumption?: number | null
          diesel_fill?: number | null
          diesel_stock?: number | null
          engine_oil_pressure?: number | null
          engine_oil_temperature?: number | null
          id?: string
          is_verified?: boolean | null
          kitchen_id?: string | null
          log_date?: string
          remarks?: string | null
          signature?: string | null
          total_kwh?: number | null
          total_running_hours?: number | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      electrical_log_reading: {
        Row: {
          created_at: string | null
          daily_log_id: string
          frequency: number | null
          ht_voltage: number | null
          id: string
          logged_by: string | null
          lt_amps: number | null
          lt_voltage: number | null
          power_factor: number | null
          reading_time: string
          remarks: string | null
          tap_no: string | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          daily_log_id: string
          frequency?: number | null
          ht_voltage?: number | null
          id?: string
          logged_by?: string | null
          lt_amps?: number | null
          lt_voltage?: number | null
          power_factor?: number | null
          reading_time: string
          remarks?: string | null
          tap_no?: string | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          daily_log_id?: string
          frequency?: number | null
          ht_voltage?: number | null
          id?: string
          logged_by?: string | null
          lt_amps?: number | null
          lt_voltage?: number | null
          power_factor?: number | null
          reading_time?: string
          remarks?: string | null
          tap_no?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "electrical_log_reading_logged_by_fkey"
            columns: ["logged_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "electrical_log_reading_logged_by_fkey"
            columns: ["logged_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "fk_daily_log"
            columns: ["daily_log_id"]
            isOneToOne: false
            referencedRelation: "daily_electrical_log"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_daily_log"
            columns: ["daily_log_id"]
            isOneToOne: false
            referencedRelation: "v_daily_electrical_log"
            referencedColumns: ["daily_log_id"]
          },
        ]
      }
      m_area: {
        Row: {
          area_name: string
          created_at: string | null
          id: string
          status: boolean | null
          zone_id: string | null
        }
        Insert: {
          area_name: string
          created_at?: string | null
          id?: string
          status?: boolean | null
          zone_id?: string | null
        }
        Update: {
          area_name?: string
          created_at?: string | null
          id?: string
          status?: boolean | null
          zone_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_area_zone_id_fkey"
            columns: ["zone_id"]
            isOneToOne: false
            referencedRelation: "m_zone"
            referencedColumns: ["id"]
          },
        ]
      }
      m_cluster: {
        Row: {
          created_at: string | null
          id: string
          name: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          name: string
        }
        Update: {
          created_at?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      m_equipment: {
        Row: {
          area_id: string | null
          created_at: string | null
          date_of_commision: string | null
          equipment_code: string | null
          id: string
          model: string | null
          name: string
          remarks: string | null
          status: boolean | null
        }
        Insert: {
          area_id?: string | null
          created_at?: string | null
          date_of_commision?: string | null
          equipment_code?: string | null
          id?: string
          model?: string | null
          name: string
          remarks?: string | null
          status?: boolean | null
        }
        Update: {
          area_id?: string | null
          created_at?: string | null
          date_of_commision?: string | null
          equipment_code?: string | null
          id?: string
          model?: string | null
          name?: string
          remarks?: string | null
          status?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "m_equipment_area_id_fkey"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "m_area"
            referencedColumns: ["id"]
          },
        ]
      }
      m_kitchen: {
        Row: {
          address: string | null
          cluster_id: string | null
          created_at: string | null
          id: string
          name: string
          status: boolean | null
        }
        Insert: {
          address?: string | null
          cluster_id?: string | null
          created_at?: string | null
          id?: string
          name: string
          status?: boolean | null
        }
        Update: {
          address?: string | null
          cluster_id?: string | null
          created_at?: string | null
          id?: string
          name?: string
          status?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "m_kitchen_cluster_id_fkey"
            columns: ["cluster_id"]
            isOneToOne: false
            referencedRelation: "m_cluster"
            referencedColumns: ["id"]
          },
        ]
      }
      m_ro_checklist_template: {
        Row: {
          created_at: string | null
          expected_condition: string | null
          id: string
          kitchen_id: string
          procedure_step: string
          sequence_no: number
          status: boolean | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          expected_condition?: string | null
          id?: string
          kitchen_id: string
          procedure_step: string
          sequence_no: number
          status?: boolean | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          expected_condition?: string | null
          id?: string
          kitchen_id?: string
          procedure_step?: string
          sequence_no?: number
          status?: boolean | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_ro_checklist_template_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_ro_checklist_template_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_ro_checklist_template_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      m_spares: {
        Row: {
          created_at: string | null
          id: string
          is_critical: boolean | null
          kitchen_id: string
          spare_code: string | null
          spare_description: string | null
          spare_name: string
          spare_type: string | null
          status: boolean | null
          uom: string | null
          vendor_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          is_critical?: boolean | null
          kitchen_id: string
          spare_code?: string | null
          spare_description?: string | null
          spare_name: string
          spare_type?: string | null
          status?: boolean | null
          uom?: string | null
          vendor_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          is_critical?: boolean | null
          kitchen_id?: string
          spare_code?: string | null
          spare_description?: string | null
          spare_name?: string
          spare_type?: string | null
          status?: boolean | null
          uom?: string | null
          vendor_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_spares_vendor_id_fkey"
            columns: ["vendor_id"]
            isOneToOne: false
            referencedRelation: "m_vendor"
            referencedColumns: ["id"]
          },
        ]
      }
      m_testing_equipment: {
        Row: {
          area_id: string | null
          calibration_frequency: string | null
          created_at: string | null
          date_of_commission: string | null
          id: string
          is_testing_completed: boolean | null
          last_calibration_date: string | null
          name: string
          next_due_date: string | null
          operating_range: string | null
          remarks: string | null
          status: boolean | null
          updated_at: string | null
        }
        Insert: {
          area_id?: string | null
          calibration_frequency?: string | null
          created_at?: string | null
          date_of_commission?: string | null
          id?: string
          is_testing_completed?: boolean | null
          last_calibration_date?: string | null
          name: string
          next_due_date?: string | null
          operating_range?: string | null
          remarks?: string | null
          status?: boolean | null
          updated_at?: string | null
        }
        Update: {
          area_id?: string | null
          calibration_frequency?: string | null
          created_at?: string | null
          date_of_commission?: string | null
          id?: string
          is_testing_completed?: boolean | null
          last_calibration_date?: string | null
          name?: string
          next_due_date?: string | null
          operating_range?: string | null
          remarks?: string | null
          status?: boolean | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_testing_equipment_area_id_fkey"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "m_area"
            referencedColumns: ["id"]
          },
        ]
      }
      m_tools: {
        Row: {
          created_at: string | null
          date_of_commision: string | null
          date_of_destroy: string | null
          id: string
          kitchen_id: string
          status: boolean | null
          tool_name: string
        }
        Insert: {
          created_at?: string | null
          date_of_commision?: string | null
          date_of_destroy?: string | null
          id?: string
          kitchen_id: string
          status?: boolean | null
          tool_name: string
        }
        Update: {
          created_at?: string | null
          date_of_commision?: string | null
          date_of_destroy?: string | null
          id?: string
          kitchen_id?: string
          status?: boolean | null
          tool_name?: string
        }
        Relationships: [
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      m_user: {
        Row: {
          address: string | null
          amp_id: string
          created_at: string | null
          department: string | null
          id: string
          mobile_no: string | null
          name: string
          role: string
          status: boolean
        }
        Insert: {
          address?: string | null
          amp_id: string
          created_at?: string | null
          department?: string | null
          id: string
          mobile_no?: string | null
          name: string
          role: string
          status?: boolean
        }
        Update: {
          address?: string | null
          amp_id?: string
          created_at?: string | null
          department?: string | null
          id?: string
          mobile_no?: string | null
          name?: string
          role?: string
          status?: boolean
        }
        Relationships: []
      }
      m_vendor: {
        Row: {
          contact_number: string | null
          contact_person: string | null
          created_at: string | null
          id: string
          kitchen_id: string
          location: string | null
          name: string
          service_center: string | null
          status: boolean | null
        }
        Insert: {
          contact_number?: string | null
          contact_person?: string | null
          created_at?: string | null
          id?: string
          kitchen_id: string
          location?: string | null
          name: string
          service_center?: string | null
          status?: boolean | null
        }
        Update: {
          contact_number?: string | null
          contact_person?: string | null
          created_at?: string | null
          id?: string
          kitchen_id?: string
          location?: string | null
          name?: string
          service_center?: string | null
          status?: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "m_vendor_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_vendor_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_vendor_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      m_zone: {
        Row: {
          created_at: string | null
          id: string
          kitchen_id: string
          name: string
          status: boolean | null
          telegram_chat_id: string | null
          zone_leader: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          kitchen_id: string
          name: string
          status?: boolean | null
          telegram_chat_id?: string | null
          zone_leader?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          kitchen_id?: string
          name?: string
          status?: boolean | null
          telegram_chat_id?: string | null
          zone_leader?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_zone_leader_fkey"
            columns: ["zone_leader"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_zone_leader_fkey"
            columns: ["zone_leader"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      machine_history_card: {
        Row: {
          authorized_by: string | null
          created_at: string | null
          critical_spares: string | null
          equipment_id: string
          id: string
          machine_name_plate_details: string | null
          prepared_by: string | null
          service_amc_person_address: string | null
          service_amc_person_name: string | null
          status: boolean | null
          updated_at: string | null
          verified_by: string | null
        }
        Insert: {
          authorized_by?: string | null
          created_at?: string | null
          critical_spares?: string | null
          equipment_id: string
          id?: string
          machine_name_plate_details?: string | null
          prepared_by?: string | null
          service_amc_person_address?: string | null
          service_amc_person_name?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Update: {
          authorized_by?: string | null
          created_at?: string | null
          critical_spares?: string | null
          equipment_id?: string
          id?: string
          machine_name_plate_details?: string | null
          prepared_by?: string | null
          service_amc_person_address?: string | null
          service_amc_person_name?: string | null
          status?: boolean | null
          updated_at?: string | null
          verified_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "machine_history_card_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_history_card_authorized_by_fkey"
            columns: ["authorized_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "machine_history_card_equipment_fkey"
            columns: ["equipment_id"]
            isOneToOne: true
            referencedRelation: "m_equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_history_card_equipment_fkey"
            columns: ["equipment_id"]
            isOneToOne: true
            referencedRelation: "v_equipment_master"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_history_card_equipment_fkey"
            columns: ["equipment_id"]
            isOneToOne: true
            referencedRelation: "v_preventive_maintenance_report"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "machine_history_card_equipment_fkey"
            columns: ["equipment_id"]
            isOneToOne: true
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "machine_history_card_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_history_card_prepared_by_fkey"
            columns: ["prepared_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "machine_history_card_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "machine_history_card_verified_by_fkey"
            columns: ["verified_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      preventive_maintenance_activity: {
        Row: {
          checklist_id: string
          condition_status: string | null
          created_at: string | null
          id: string
          observation: string | null
          schedule_activity: string
          standard_condition: string | null
          updated_at: string | null
        }
        Insert: {
          checklist_id: string
          condition_status?: string | null
          created_at?: string | null
          id?: string
          observation?: string | null
          schedule_activity: string
          standard_condition?: string | null
          updated_at?: string | null
        }
        Update: {
          checklist_id?: string
          condition_status?: string | null
          created_at?: string | null
          id?: string
          observation?: string | null
          schedule_activity?: string
          standard_condition?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "preventive_maintenance_activity_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "preventive_maintenance_checklist"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_maintenance_activity_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_report"
            referencedColumns: ["checklist_id"]
          },
        ]
      }
      preventive_maintenance_checklist: {
        Row: {
          created_at: string | null
          date: string
          equipment_id: string
          frequency: string | null
          id: string
          status: boolean | null
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          date: string
          equipment_id: string
          frequency?: string | null
          id?: string
          status?: boolean | null
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          date?: string
          equipment_id?: string
          frequency?: string | null
          id?: string
          status?: boolean | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "preventive_maintenance_checklist_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "m_equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_maintenance_checklist_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_equipment_master"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_maintenance_checklist_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_report"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "preventive_maintenance_checklist_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["equipment_id"]
          },
        ]
      }
      rep_preventive_machine_schedule: {
        Row: {
          achieved_date: string | null
          created_at: string | null
          done_by: string | null
          equipment_id: string
          frequency: string | null
          id: string
          is_achieved: boolean | null
          is_planned: boolean | null
          plan_date: string
          remarks: string | null
          status: boolean | null
          updated_at: string | null
        }
        Insert: {
          achieved_date?: string | null
          created_at?: string | null
          done_by?: string | null
          equipment_id: string
          frequency?: string | null
          id?: string
          is_achieved?: boolean | null
          is_planned?: boolean | null
          plan_date: string
          remarks?: string | null
          status?: boolean | null
          updated_at?: string | null
        }
        Update: {
          achieved_date?: string | null
          created_at?: string | null
          done_by?: string | null
          equipment_id?: string
          frequency?: string | null
          id?: string
          is_achieved?: boolean | null
          is_planned?: boolean | null
          plan_date?: string
          remarks?: string | null
          status?: boolean | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "preventive_machine_schedule_done_by_fkey"
            columns: ["done_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_machine_schedule_done_by_fkey"
            columns: ["done_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "preventive_machine_schedule_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "m_equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_machine_schedule_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_equipment_master"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "preventive_machine_schedule_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_report"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "preventive_machine_schedule_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["equipment_id"]
          },
        ]
      }
      spare_monthly_history: {
        Row: {
          created_at: string | null
          history_month: number
          history_year: number
          id: string
          kitchen_id: string
          maintained_stock: number
          on_stock: number
          spare_id: string
        }
        Insert: {
          created_at?: string | null
          history_month: number
          history_year: number
          id?: string
          kitchen_id: string
          maintained_stock?: number
          on_stock?: number
          spare_id: string
        }
        Update: {
          created_at?: string | null
          history_month?: number
          history_year?: number
          id?: string
          kitchen_id?: string
          maintained_stock?: number
          on_stock?: number
          spare_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_history_spare"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "m_spares"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_history_spare"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "v_critical_spare_parts_monthly_report"
            referencedColumns: ["spare_id"]
          },
          {
            foreignKeyName: "fk_history_spare"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "v_critical_spare_parts_report"
            referencedColumns: ["spare_id"]
          },
        ]
      }
      spare_ticket: {
        Row: {
          id: string
          logged_by_id: string | null
          spare_id: string
          ticket_id: string
          used_qty: number
          used_qty_time: string | null
        }
        Insert: {
          id?: string
          logged_by_id?: string | null
          spare_id: string
          ticket_id: string
          used_qty?: number
          used_qty_time?: string | null
        }
        Update: {
          id?: string
          logged_by_id?: string | null
          spare_id?: string
          ticket_id?: string
          used_qty?: number
          used_qty_time?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "spare_ticket_logged_by_id_fkey"
            columns: ["logged_by_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spare_ticket_logged_by_id_fkey"
            columns: ["logged_by_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "spare_ticket_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "m_spares"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spare_ticket_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "v_critical_spare_parts_monthly_report"
            referencedColumns: ["spare_id"]
          },
          {
            foreignKeyName: "spare_ticket_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: false
            referencedRelation: "v_critical_spare_parts_report"
            referencedColumns: ["spare_id"]
          },
          {
            foreignKeyName: "spare_ticket_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spare_ticket_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_breakdown_intimation__report"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spare_ticket_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_complaint_register"
            referencedColumns: ["id"]
          },
        ]
      }
      spare_tracker: {
        Row: {
          current_qty: number
          id: string
          last_updated: string | null
          min_qty_alert: number
          spare_id: string
          total_qty: number
        }
        Insert: {
          current_qty?: number
          id?: string
          last_updated?: string | null
          min_qty_alert?: number
          spare_id: string
          total_qty?: number
        }
        Update: {
          current_qty?: number
          id?: string
          last_updated?: string | null
          min_qty_alert?: number
          spare_id?: string
          total_qty?: number
        }
        Relationships: [
          {
            foreignKeyName: "spare_tracker_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: true
            referencedRelation: "m_spares"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "spare_tracker_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: true
            referencedRelation: "v_critical_spare_parts_monthly_report"
            referencedColumns: ["spare_id"]
          },
          {
            foreignKeyName: "spare_tracker_spare_id_fkey"
            columns: ["spare_id"]
            isOneToOne: true
            referencedRelation: "v_critical_spare_parts_report"
            referencedColumns: ["spare_id"]
          },
        ]
      }
      ticket_equipments: {
        Row: {
          equipment_id: string | null
          id: string
          testing_equipment_id: string | null
          ticket_id: string
        }
        Insert: {
          equipment_id?: string | null
          id?: string
          testing_equipment_id?: string | null
          ticket_id: string
        }
        Update: {
          equipment_id?: string | null
          id?: string
          testing_equipment_id?: string | null
          ticket_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_equipments_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "m_equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_equipment_master"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_report"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "ticket_equipments_equipment_id_fkey"
            columns: ["equipment_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["equipment_id"]
          },
          {
            foreignKeyName: "ticket_equipments_testing_equipment_id_fkey"
            columns: ["testing_equipment_id"]
            isOneToOne: false
            referencedRelation: "m_testing_equipment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_testing_equipment_id_fkey"
            columns: ["testing_equipment_id"]
            isOneToOne: false
            referencedRelation: "v_testing_equipment_master"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_breakdown_intimation__report"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_equipments_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_complaint_register"
            referencedColumns: ["id"]
          },
        ]
      }
      ticket_media: {
        Row: {
          content_type: string | null
          created_at: string | null
          file_name: string | null
          file_size: number | null
          id: string
          media_type: string | null
          media_url: string
          ticket_id: string | null
          upload_stage: string | null
          uploaded_by: string | null
        }
        Insert: {
          content_type?: string | null
          created_at?: string | null
          file_name?: string | null
          file_size?: number | null
          id?: string
          media_type?: string | null
          media_url: string
          ticket_id?: string | null
          upload_stage?: string | null
          uploaded_by?: string | null
        }
        Update: {
          content_type?: string | null
          created_at?: string | null
          file_name?: string | null
          file_size?: number | null
          id?: string
          media_type?: string | null
          media_url?: string
          ticket_id?: string | null
          upload_stage?: string | null
          uploaded_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ticket_media_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_media_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_breakdown_intimation__report"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_media_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_complaint_register"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_media_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_media_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      ticket_status_history: {
        Row: {
          changed_by: string
          created_at: string | null
          from_status: string | null
          id: string
          ticket_id: string
          to_status: string
        }
        Insert: {
          changed_by: string
          created_at?: string | null
          from_status?: string | null
          id?: string
          ticket_id: string
          to_status: string
        }
        Update: {
          changed_by?: string
          created_at?: string | null
          from_status?: string | null
          id?: string
          ticket_id?: string
          to_status?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_status_history_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_status_history_changed_by_fkey"
            columns: ["changed_by"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "ticket_status_history_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_status_history_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_breakdown_intimation__report"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_status_history_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_complaint_register"
            referencedColumns: ["id"]
          },
        ]
      }
      ticket_tools: {
        Row: {
          employee_id: string
          id: string
          is_vacant: boolean | null
          return_time: string | null
          taken_time: string | null
          ticket_id: string
          tool_id: string
        }
        Insert: {
          employee_id: string
          id?: string
          is_vacant?: boolean | null
          return_time?: string | null
          taken_time?: string | null
          ticket_id: string
          tool_id: string
        }
        Update: {
          employee_id?: string
          id?: string
          is_vacant?: boolean | null
          return_time?: string | null
          taken_time?: string | null
          ticket_id?: string
          tool_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "ticket_tools_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_tools_employee_id_fkey"
            columns: ["employee_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "ticket_tools_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "tickets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_tools_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_breakdown_intimation__report"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_tools_ticket_id_fkey"
            columns: ["ticket_id"]
            isOneToOne: false
            referencedRelation: "v_complaint_register"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ticket_tools_tool_id_fkey"
            columns: ["tool_id"]
            isOneToOne: false
            referencedRelation: "m_tools"
            referencedColumns: ["id"]
          },
        ]
      }
      tickets: {
        Row: {
          action_taken: string | null
          admin_verified: boolean | null
          area_id: string | null
          assigned_to_id: string | null
          breakdown_time: string | null
          category: string | null
          cause_of_issue: string | null
          custom_equipment: string | null
          id: string
          kitchen_id: string
          priority: string
          raised_by_id: string
          raiser_verified: boolean | null
          repair_start_time: string | null
          status: string
          telegram_message_id: string | null
          ticket_completion_time: string | null
          ticket_no: string | null
          ticket_raised_time: string | null
          title: string
          updated_at: string | null
          verified_by_id: string | null
        }
        Insert: {
          action_taken?: string | null
          admin_verified?: boolean | null
          area_id?: string | null
          assigned_to_id?: string | null
          breakdown_time?: string | null
          category?: string | null
          cause_of_issue?: string | null
          custom_equipment?: string | null
          id?: string
          kitchen_id: string
          priority: string
          raised_by_id: string
          raiser_verified?: boolean | null
          repair_start_time?: string | null
          status?: string
          telegram_message_id?: string | null
          ticket_completion_time?: string | null
          ticket_no?: string | null
          ticket_raised_time?: string | null
          title: string
          updated_at?: string | null
          verified_by_id?: string | null
        }
        Update: {
          action_taken?: string | null
          admin_verified?: boolean | null
          area_id?: string | null
          assigned_to_id?: string | null
          breakdown_time?: string | null
          category?: string | null
          cause_of_issue?: string | null
          custom_equipment?: string | null
          id?: string
          kitchen_id?: string
          priority?: string
          raised_by_id?: string
          raiser_verified?: boolean | null
          repair_start_time?: string | null
          status?: string
          telegram_message_id?: string | null
          ticket_completion_time?: string | null
          ticket_no?: string | null
          ticket_raised_time?: string | null
          title?: string
          updated_at?: string | null
          verified_by_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tickets_area_id_fkey"
            columns: ["area_id"]
            isOneToOne: false
            referencedRelation: "m_area"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_assigned_to_id_fkey"
            columns: ["assigned_to_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_assigned_to_id_fkey"
            columns: ["assigned_to_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "tickets_raised_by_id_fkey"
            columns: ["raised_by_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_raised_by_id_fkey"
            columns: ["raised_by_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
          {
            foreignKeyName: "tickets_verified_by_id_fkey"
            columns: ["verified_by_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_verified_by_id_fkey"
            columns: ["verified_by_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      user_fcm_tokens: {
        Row: {
          created_at: string | null
          id: string
          token: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          token: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          token?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "user_fcm_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_fcm_tokens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      user_kitchens: {
        Row: {
          created_at: string | null
          id: string
          kitchen_id: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          kitchen_id: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          kitchen_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_kitchens_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_kitchens_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "user_kitchens_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "user_kitchens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_kitchens_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
      user_report_access: {
        Row: {
          created_at: string | null
          id: string
          kitchen_id: string
          report_code: string
          user_id: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          kitchen_id: string
          report_code: string
          user_id: string
        }
        Update: {
          created_at?: string | null
          id?: string
          kitchen_id?: string
          report_code?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_report_access_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_report_access_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "user_report_access_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "user_report_access_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "m_user"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_report_access_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "v_preventive_maintenance_schedule"
            referencedColumns: ["done_by_id"]
          },
        ]
      }
    }
    Views: {
      v_boiler_log_report: {
        Row: {
          air_pressure: number | null
          aph_il: number | null
          aph_ol: number | null
          authorized_by: string | null
          blowdown_pit_level: string | null
          blowdown_water_hardness: string | null
          blowdown_water_ph: string | null
          blowdown_water_tds: string | null
          boiler_end_time: string | null
          boiler_start_time: string | null
          briquettes_closing_stock_1: number | null
          briquettes_closing_stock_2: number | null
          briquettes_consumption_1: number | null
          briquettes_consumption_2: number | null
          briquettes_opening_stock_1: number | null
          briquettes_opening_stock_2: number | null
          condenset_closing_time: string | null
          condenset_opening_time: string | null
          created_at: string | null
          detail_id: string | null
          drum_level: number | null
          entry_created_at: string | null
          entry_id: string | null
          entry_time: string | null
          feed_tank_level: number | null
          feed_water_hardness: string | null
          feed_water_ph: string | null
          feed_water_tds: string | null
          final_remarks: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          log_date: string | null
          log_id: string | null
          main_valve_close_time: string | null
          main_valve_open_time: string | null
          operator_1_name: string | null
          operator_1_sign: string | null
          operator_2_name: string | null
          operator_2_sign: string | null
          operator_3_name: string | null
          operator_3_sign: string | null
          operator_4_name: string | null
          operator_4_sign: string | null
          prepared_by: string | null
          recovery: number | null
          sequence_no: number | null
          status: boolean | null
          steam_pressure: number | null
          total_running_hours: number | null
          updated_at: string | null
          verified_by: string | null
        }
        Relationships: []
      }
      v_breakdown_intimation__report: {
        Row: {
          action_taken: string | null
          breakdown_time: string | null
          cause_of_issue: string | null
          equipment_code: string | null
          id: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          machine_name: string | null
          priority: string | null
          raised_by: string | null
          repair_start_time: string | null
          spare: string | null
          status: string | null
          ticket_completion_time: string | null
          ticket_no: string | null
          ticket_raised_time: string | null
          title: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_complaint_register: {
        Row: {
          area: string | null
          assigned_to: string | null
          cause_of_issue: string | null
          id: string | null
          kitchen_id: string | null
          machine_name: string | null
          raised_by: string | null
          repair_start_time: string | null
          ticket_completion_time: string | null
          ticket_no: string | null
          ticket_raised_time: string | null
          title: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "tickets_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_critical_spare_parts_monthly_report: {
        Row: {
          history_id: string | null
          history_month: number | null
          history_year: number | null
          kitchen_id: string | null
          kitchen_name: string | null
          maintained_stock: number | null
          on_stock: number | null
          spare_code: string | null
          spare_id: string | null
          spare_name: string | null
          spare_type: string | null
          uom: string | null
        }
        Relationships: []
      }
      v_critical_spare_parts_report: {
        Row: {
          created_at: string | null
          kitchen_id: string | null
          maintained_stock: number | null
          on_stock: number | null
          spare_code: string | null
          spare_id: string | null
          spare_name: string | null
          spare_type: string | null
          uom: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_spares_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_daily_electrical_log: {
        Row: {
          authorized_by_name: string | null
          created_at: string | null
          daily_kvah_consumption: number | null
          daily_kwh_consumption: number | null
          daily_log_id: string | null
          frequency: number | null
          ht_voltage: number | null
          kitchen_id: string | null
          kitchen_name: string | null
          kvah_closing: number | null
          kvah_opening: number | null
          kwh_closing: number | null
          kwh_opening: number | null
          log_date: string | null
          logged_by_name: string | null
          lt_amps: number | null
          lt_voltage: number | null
          power_factor: number | null
          prepared_by_name: string | null
          reading_id: string | null
          reading_time: string | null
          remarks: string | null
          status: boolean | null
          tap_no: string | null
          updated_at: string | null
          verified_by_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "daily_electrical_log_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_dg_set_logbook: {
        Row: {
          battery_voltage: number | null
          coolant_temperature: number | null
          created_at: string | null
          dg_frequency: number | null
          diesel_consumption: number | null
          diesel_fill: number | null
          diesel_stock: number | null
          engine_oil_pressure: number | null
          engine_oil_temperature: number | null
          id: string | null
          is_verified: boolean | null
          kitchen_id: string | null
          kitchen_name: string | null
          log_date: string | null
          remarks: string | null
          signature: string | null
          total_kwh: number | null
          total_running_hours: number | null
          updated_at: string | null
        }
        Relationships: [
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "dg_set_logbook_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_equipment_master: {
        Row: {
          area: string | null
          created_at: string | null
          date_of_commision: string | null
          id: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          machine_name: string | null
          model: string | null
          remarks: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_machine_history_card: {
        Row: {
          authorized_by: string | null
          critical_spares: string | null
          date_of_installation: string | null
          down_time: string | null
          equipment_code: string | null
          equipment_id: string | null
          history_date: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          location: string | null
          machine_name: string | null
          machine_name_plate_details: string | null
          maintenance_carried_out: string | null
          maintenance_details: string | null
          nature_of_work: string | null
          prepared_by: string | null
          service_amc_person_address: string | null
          service_amc_person_name: string | null
          sign_by: string | null
          source_type: string | null
          verified_by: string | null
        }
        Relationships: []
      }
      v_preventive_maintenance_report: {
        Row: {
          activity_id: string | null
          checklist_date: string | null
          checklist_id: string | null
          condition_status: string | null
          equipment_id: string | null
          frequency: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          machine_name: string | null
          observation: string | null
          schedule_activity: string | null
          standard_condition: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_preventive_maintenance_schedule: {
        Row: {
          achieved_date: string | null
          done_by_id: string | null
          done_by_name: string | null
          equipment_code: string | null
          equipment_id: string | null
          id: string | null
          is_achieved: boolean | null
          is_planned: boolean | null
          kitchen_id: string | null
          kitchen_name: string | null
          machine_name: string | null
          plan_date: string | null
          remarks: string | null
          status: boolean | null
        }
        Relationships: [
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_ro_checklist_report: {
        Row: {
          authorized_by: string | null
          check_symbol: string | null
          created_at: string | null
          detail_id: string | null
          expected_condition: string | null
          feed_water: number | null
          is_checked: boolean | null
          kitchen_id: string | null
          kitchen_name: string | null
          log_date: string | null
          log_id: string | null
          prepared_by: string | null
          procedure_step: string | null
          product_water: number | null
          reject_water: number | null
          remarks: string | null
          sequence_no: number | null
          updated_at: string | null
          verified_by: string | null
        }
        Relationships: []
      }
      v_testing_equipment_master: {
        Row: {
          calibration_frequency: string | null
          created_at: string | null
          date_of_commission: string | null
          equipment_name: string | null
          id: string | null
          is_testing_completed: boolean | null
          kitchen_id: string | null
          kitchen_name: string | null
          last_calibration_date: string | null
          location: string | null
          next_due_date: string | null
          operating_range: string | null
          remarks: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_zone_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
      v_tools_tackles_report: {
        Row: {
          employee_name: string | null
          id: string | null
          kitchen_id: string | null
          kitchen_name: string | null
          return_hour: string | null
          return_time: string | null
          taken_date: string | null
          taken_hour: string | null
          taken_time: string | null
          ticket_no: string | null
          tool_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "m_kitchen"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_boiler_log_report"
            referencedColumns: ["kitchen_id"]
          },
          {
            foreignKeyName: "m_tools_kitchen_id_fkey"
            columns: ["kitchen_id"]
            isOneToOne: false
            referencedRelation: "v_ro_checklist_report"
            referencedColumns: ["kitchen_id"]
          },
        ]
      }
    }
    Functions: {
      calculate_next_due_date: {
        Args: { freq: string; last_date: string }
        Returns: string
      }
      create_daily_ro_checklist: { Args: never; Returns: undefined }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
