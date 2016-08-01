name "media_servers"
description "This role contains nodes, which act as media servers"
run_list "recipe[ntp]"
default_attributes 'ntp' => {
'ntpdate' => {
'disable' => true
}
}
