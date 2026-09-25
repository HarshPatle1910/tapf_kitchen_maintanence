-- Add assigned_to_time column to tickets
ALTER TABLE tickets 
ADD COLUMN IF NOT EXISTS assigned_to_time TIMESTAMPTZ;

-- Backfill assigned_to_time for all tickets that currently have an assigned worker
UPDATE tickets t
SET assigned_to_time = COALESCE(
    (
        SELECT h.created_at
        FROM ticket_status_history h
        WHERE h.ticket_id = t.id AND h.to_status = 'ASSIGNED'
        ORDER BY h.created_at ASC
        LIMIT 1
    ),
    t.repair_start_time,
    t.ticket_raised_time
)
WHERE t.assigned_to_id IS NOT NULL
  AND t.assigned_to_time IS NULL;

-- Trigger to automatically track assigned_to_time on worker assignment
CREATE OR REPLACE FUNCTION set_ticket_assigned_to_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.assigned_to_id IS NOT NULL THEN
        IF TG_OP = 'INSERT' THEN
            IF NEW.assigned_to_time IS NULL THEN
                NEW.assigned_to_time = NOW();
            END IF;
        ELSIF TG_OP = 'UPDATE' THEN
            IF OLD.assigned_to_id IS NULL OR NEW.assigned_to_id <> OLD.assigned_to_id THEN
                IF NEW.assigned_to_time IS NULL OR NEW.assigned_to_time = OLD.assigned_to_time THEN
                    NEW.assigned_to_time = NOW();
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_ticket_assigned_to_time ON tickets;
CREATE TRIGGER trg_set_ticket_assigned_to_time
BEFORE INSERT OR UPDATE OF assigned_to_id ON tickets
FOR EACH ROW
EXECUTE FUNCTION set_ticket_assigned_to_time();
