#
# Cookbook Name:: learn_chef_httpd
# Recipe:: default
#
# Copyright (c) 2015 brianoflan (http://github.com/brianoflan), The MIT License (http://opensource.org/licenses/MIT).

package 'httpd'

service 'httpd' do
  action [:enable, :start]
end

template '/var/www/html/index.html' do
  source 'index.html.erb'
end

service 'iptables' do
  action :stop
end
