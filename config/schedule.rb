# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# command:bashコマンドの実行
# rake:rakeタスクの実行
# runner:Rails内のメソッドの実行
# script:scriptの実行

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end
set :output, 'log/whenever.log'

# [例] 毎週日曜18:00
every 1.day, at: '00:00 am' do
  runner "CompanyController.reset_point"
end

# every 1.minute do
#   runner "CompanyController.reset_point"
# end

# Learn more: http://github.com/javan/whenever
