require File.expand_path(File.join(File.dirname(__FILE__),'gtest.rb'))

# see http://news.ycombinator.com/item?id=2046796 for the sample split test used

SPLIT_GROUP_SIZE = 33_500

email_results = {
  :merry_christmas => [SPLIT_GROUP_SIZE, 1832],
  :happy_holidays => [SPLIT_GROUP_SIZE, 971],
  :merry_and_happy => [SPLIT_GROUP_SIZE, 943]}

email_gtest = GTest.new email_results

# for the gstat and confidence ratio
puts email_gtest.compare_split_groups

# for humans
puts email_gtest.for_humans
