# ptp jitter analyzer
LUA script to compute jitter on PTP sync messages 

Post dissector that computes the instantaneous jitter as the difference between the receive dates or SYNC messages, and the timestamp in the FOLLOWUP messages.
It may be graphed out in Wireshark in Statistics->GraphIO menu, and selecting ptp_jitter.jitter as Y Field.

Restrictions: PTP2, two steps only. 
