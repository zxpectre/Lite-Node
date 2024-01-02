CREATE OR REPLACE FUNCTION {{SCHEMA}}.blocks()
RETURNS TABLE (
  hash text,
  epoch_no word31type,
  abs_slot word63type,
  epoch_slot word31type,
  block_no word31type,
  block_size word31type,
  block_time integer,
  tx_count bigint,
  vrf_key character varying,
  proto_major word31type,
  proto_minor word31type,
  op_cert_counter word63type,
  parent_hash text
)
LANGUAGE sql STABLE
AS $$
  SELECT
    ENCODE(b.hash::bytea, 'hex') AS hash,
    b.epoch_no AS epoch_no,
    b.slot_no AS abs_slot,
    b.epoch_slot_no AS epoch_slot,
    b.block_no AS block_height,
    b.size AS block_size,
    EXTRACT(EPOCH FROM b.time)::integer AS block_time,
    b.tx_count,
    b.vrf_key,
    b.proto_major,
    b.proto_minor,
    b.op_cert_counter,
    (
      SELECT ENCODE(tb.hash::bytea, 'hex')
      FROM block tb
      WHERE id = b.previous_id
    ) AS parent_hash
  FROM block AS b
  LEFT JOIN slot_leader AS sl ON b.slot_leader_id = sl.id
  ORDER BY b.id DESC;
$$;

COMMENT ON FUNCTION {{SCHEMA}}.blocks IS 'Get detailed information about all blocks (paginated - latest first)';
