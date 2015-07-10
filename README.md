check_f5_ltm_pool
=================

Nagios Plugin for Checking F5 LTM Pool / Pool Member Status &amp; Performance

## Pool Mode
**Checks the Pool Status**
- Warns if not all members are up
- Critical if pool is down
- Unknown if specified pool can't be found

```
define command{
 command_name    check_f5_vip
 command_line    $USER1$/check_f5_ltm_pool.pl -H $USER6$ -C $USER4$ -P $_HOSTF5_POOL$ -t 25
}
```
### Member Mode
