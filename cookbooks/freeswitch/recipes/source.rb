#include_recipe 'apt'

#node['freeswitch']['source']['dependencies'].each { |d| package d }

execute "apt_update" do
command "bash -c 'wget -O - https://files.freeswitch.org/repo/deb/debian/freeswitch_archive_g0.pub | apt-key add - && echo deb http://files.freeswitch.org/repo/deb/freeswitch-1.6/ jessie main > /etc/apt/sources.list.d/freeswitch.list && apt-get update && apt-get install -y --force-yes freeswitch-video-deps-most && git config --global pull.rebase true'"
end
execute "git_clone" do
  command "git clone --depth 1 -b #{node['freeswitch']['source']['git_branch']} #{node['freeswitch']['source']['git_uri']} freeswitch"
  cwd "/usr/local/src"
  creates "/usr/local/src/freeswitch"
end

template "/usr/local/src/freeswitch/modules.conf" do
  source "modules.conf.erb"
  variables modules: node['freeswitch']['source']['modules']
end

script "compile_freeswitch" do
  interpreter "/bin/bash"
  cwd "/usr/local/src/freeswitch"
  code <<-EOF
  ./bootstrap.sh
  ./configure 
  make clean
  make
 # #{"make config-#{node['freeswitch']['source']['config_template']}" if node['freeswitch']['source']['config_template']}
  make install
EOF
  not_if "test -f #{node['freeswitch']['binpath']}/freeswitch"
end

group node['freeswitch']['group'] do
  action :create
end

# create non-root user
user node['freeswitch']['user'] do
  system true
  shell "/bin/bash"
  home node['freeswitch']['homedir']
  gid node['freeswitch']['group']
end

# change ownership of homedir
execute "fs_homedir_ownership" do
  cwd node['freeswitch']['homedir']
  command "chown -R #{node['freeswitch']['user']}:#{node['freeswitch']['group']} ."
end

%w{
  /usr/local/freeswitch
  /usr/local/freeswitch/db
  /usr/local/freeswitch/recordings
  /usr/local/freeswitch/storage
  /usr/local/freeswitch
  /var/run/freeswitch
}.each do |dir|
  directory dir do
    owner node['freeswitch']['user']
    group node['freeswitch']['group']
  end
end
