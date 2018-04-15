# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

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
require File.expand_path(File.dirname(__FILE__) + '/environment')

# TODO: temporary fix, need time to investigate
job_type :runner, "cd :path && RAILS_ENV=#{@environment} bin/rails runner -e :environment ':task' :output"

set :output, 'log/whenever.log'

every 1.day, at: '00:00 am' do
  runner "CompanyController.reset_point"
end

# Learn more: http://github.com/javan/whenever

every :monday, :at => '12:00 pm'
  runner "ArticlesController.batch"
end

every 1.day, at: '5:30 pm' do
  runner "ArticlesController.batch"
end