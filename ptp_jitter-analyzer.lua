-- PTP Jitter Analyzer postdissector
-- Computes jitter between SYNC messages.
-- (c) 10 May 2021, Eric Heurtel SOUND4 Ltd
-- License : MIT

-- declare some Fields to be read
sync_ts_f = Field.new("ptp.v2.sdr.origintimestamp.seconds")
sync_tsns_f = Field.new("ptp.v2.sdr.origintimestamp.nanoseconds")
flup_ts_f = Field.new("ptp.v2.fu.preciseorigintimestamp.seconds")
flup_tsns_f = Field.new("ptp.v2.fu.preciseorigintimestamp.nanoseconds")
ptp_seqid_f = Field.new("ptp.v2.sequenceid")
frame_time_f = Field.new("frame.time_epoch")
-- declare our (pseudo) protocol
ptp_jitter_proto = Proto("ptp_jitter","PTP Postdissector")
-- create the fields for our "protocol"
dts_F = ProtoField.string("ptp_jitter.dts","Delta Timestamp")
dft_F = ProtoField.string("ptp_jitter.dft","Delta FrameTime")
did_F = ProtoField.string("ptp_jitter.did","Delta Seq ID")
jitter_F = ProtoField.int32("ptp_jitter.jitter","Jitter ns")
-- add the field to the protocol
ptp_jitter_proto.fields = {dts_F, dft_F, did_F, jitter_F}
-- create a function to "postdissect" each frame

local last_sync = {} -- the last time a SYNC packet was seen between two nodes
local last_followup = {} -- the last time a FOLLOWUP packet was seen between two nodes

function ptp_jitter_proto.dissector(buffer,pinfo,tree)
    -- obtain the current values the protocol fields
    local sync_ts = sync_ts_f()
    local flup_ts = flup_ts_f()
    local flup_tsns= flup_tsns_f()
    local seq_id = ptp_seqid_f().value
    if sync_ts then	-- Sync Message : record the Frame Date
       local time_epoch = frame_time_f()
       local subtree = tree:add(ptp_jitter_proto,"PTP Analysis Data")
       subtree:add(dft_F,tostring(seq_id) .. ":" .. tostring(time_epoch.value.secs) .. "." .. tostring(time_epoch.value.nsecs))
       last_sync[seq_id] = {time_epoch = time_epoch.value}
    end
    if flup_ts and last_sync[seq_id] and last_sync[seq_id].time_epoch then	-- Followup Message : computes jitter = dts - dft
       local subtree = tree:add(ptp_jitter_proto,"PTP Analysis Data")
       local last_seq_id = seq_id-1
       if last_seq_id < 0 then last_seq_id = 65535 end
       -- dft = difference between the arrival date of SYNC messages
       local time_epoch = last_sync[seq_id].time_epoch
       if last_followup[last_seq_id] and last_followup[last_seq_id].tsns then
           local last_tsns = last_followup[last_seq_id].tsns
           -- dts = difference between the timestamps of FOLLOWUP messages
           local tsns = flup_tsns.value
           if tsns < last_tsns then tsns = tsns + 1000000000 end
           local last_time_epoch = last_followup[last_seq_id].time_epoch
           subtree:add(dts_F, tostring(tsns) .. "-" .. tostring(last_tsns) .. "=" .. tostring(tsns-last_tsns))
           subtree:add(dft_F,tostring(time_epoch) .. "-" .. tostring(last_time_epoch) .. "=" .. tostring(time_epoch - last_time_epoch))
           local jitter = (tsns-last_tsns) - (time_epoch - last_time_epoch).nsecs
           subtree:add(jitter_F,jitter)
       end
       subtree:add(did_F,tostring(last_seq_id) .. "->" .. tostring(seq_id) )
       last_followup[seq_id] = { time_epoch = time_epoch, tsns = tonumber(flup_tsns.value) }
    end
end
-- register our protocol as a postdissector
register_postdissector(ptp_jitter_proto)
