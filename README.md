check_f5_ltm_pool
=================

Nagios Plugin for Checking F5 LTM Pool / Pool Member Status &amp; Performance


# Pool Mode
**Checks the Pool Status**
- Warns if not all members are up
- Critical if pool is down
- Unknown if specified pool can't be found

**Example**
```
# check_f5_ltm_pool.pl -H some.host.com -C public -P /Common/MYPOOL -t 25
```
**Performance Data**
- Packets In
- Bytes In
- Packets Out
- Bytes Out
- Current Connections

# Member Mode
**Checks the Pool Member Status**
- Critical if member is not Green
- Unknown if specified pool or pool member can't be found

**Example**
```
# check_f5_ltm_pool.pl -H some.host.com -C public -P /Common/MYPOOL -M SOME-NODE-NAME -S 80
```

**Performance Data**
- Packets In
- Bytes In
- Packets Out
- Bytes Out
- Current Connections
- Current Sessions
- Current Connections Per Second
