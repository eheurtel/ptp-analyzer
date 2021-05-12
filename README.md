# ptp jitter analyzer
Wireshark LUA script to compute jitter on PTP sync messages 

Post dissector that computes the instantaneous jitter as the difference between the receive dates and the timestamp in consecutive SYNC messages.
The dates are corrected by the value given in FOLLOWUP messages.

It may help solving PTP issues.

It may be graphed out in Wireshark in Statistics->GraphIO menu, and selecting ptp_jitter.jitter as Y Field. Select "ptp.v2.messageid==8" as "Display filter" and "MAX" as "Y axis"


Restrictions: PTP2, two steps only. 

Usage : wireshark ptp_small_followup.pcap -X lua_script:ptp_postdissector.lua
