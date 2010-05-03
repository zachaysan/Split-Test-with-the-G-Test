require 'gtest'
module GTestHelperMethods
  def generate_gtest_scenario(number_of_groups)
    split_test_hash = {}
    for i in 1..number_of_groups do
      split_test_hash["split_group_#{i}"] = [900 + rand(200), 15 + rand(30)]
    end
    split_test_hash
  end
end

describe GTest do
  include GTestHelperMethods
  before(:all) do
    sample_gtest = generate_gtest_scenario(2)
    @gtest = GTest.new sample_gtest
  end
  it "should not blow up on init given a simple ab test" do
    sample_gtest = generate_gtest_scenario(2)
    small_gtest = GTest.new sample_gtest
  end
  it "should be able to load multiple test groups" do
    sample_gtest = generate_gtest_scenario(5)
    large_gtest = GTest.new sample_gtest
  end
  it "should allow a minimum number of successes to be set, with a default of 10" do
    @gtest.min_successes = 30
  end
  it "should only allow nested arrays as a measure" do
    @gtest.find_best_performing
    sample_incorrect_gtest = {"first_split_group" => "200:15", "second_split_group" => "205:15"}
    incorrect_gtest = GTest.new sample_incorrect_gtest
    lambda { incorrect_gtest.assure_format }.should raise_error(GTestException)
  end
  it "should correctly find the best performing split group" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100], 
      :middle_split_group  => [1000, 125]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.find_best_performing.should == :winning_split_group
  end
  it "should allow the Yates continuity correction to be turned off or on" do
    @gtest.yates = :off
    @gtest.yates.should == :off
  end
  
  it "should return the correct G-test statistic with yates off and only two groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :off
    split_results = predetermined_gtest.compare_split_groups
    gstat, confidence = split_results[:loosing_split_group]
    rounded_gstat = (gstat*10_000).round.to_f / 10_000
    rounded_gstat.should == 11.4965
  end
  it "should return the correct confidence with yates off and only two groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :off
    split_results = predetermined_gtest.compare_split_groups
    gstat, confidence = split_results[:loosing_split_group]
    rounded_confidence = (confidence*10_000).round.to_f / 10_000
    rounded_confidence.should == 0.9993
  end
  it "should return the correct G-test statistic with yates on and only two groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :on
    
    split_results = predetermined_gtest.compare_split_groups
    gstat, confidence = split_results[:loosing_split_group]
    rounded_gstat = (gstat*10_000).round.to_f / 10_000
    rounded_gstat.should == 11.0386
  end
  it "should return the correct confidence with yates on and only two groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :on
    split_results = predetermined_gtest.compare_split_groups
    gstat, confidence = split_results[:loosing_split_group]
    rounded_confidence = (confidence*10_000).round.to_f / 10_000
    rounded_confidence.should == 0.9991
  end
  it "should return the correct G-test statistics with yates on and multiple groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100], 
      :middle_split_group  => [1000, 125]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :on
    split_results = predetermined_gtest.compare_split_groups
    array_of_g_stats = [(split_results[:loosing_split_group][0]*10_000).round.to_f / 10_000, 
                        (split_results[:middle_split_group][0]*10_000).round.to_f / 10_000]
    array_of_g_stats.should == [11.0386, 2.4311]
  end
  it "should return the correct G-test statistics with yates on and multiple groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100], 
      :middle_split_group  => [1000, 125]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :on
    split_results = predetermined_gtest.compare_split_groups
    array_of_confidences = [(split_results[:loosing_split_group][1]*10_000).round.to_f / 10_000, 
                        (split_results[:middle_split_group][1]*10_000).round.to_f / 10_000]
    array_of_confidences.should == [0.9991, 0.8811]
  end
  it "should return the correct G-test statistics with yates off and multiple groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100], 
      :middle_split_group  => [1000, 125]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :off
    split_results = predetermined_gtest.compare_split_groups
    array_of_g_stats = [(split_results[:loosing_split_group][0]*10_000).round.to_f / 10_000, 
                        (split_results[:middle_split_group][0]*10_000).round.to_f / 10_000]
    array_of_g_stats.should == [11.4965, 2.6382]
  end
  it "should return the correct G-test statistics with yates on and multiple groups" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 150], 
      :loosing_split_group => [1000, 100], 
      :middle_split_group  => [1000, 125]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    predetermined_gtest.yates = :off
    split_results = predetermined_gtest.compare_split_groups
    array_of_confidences = [(split_results[:loosing_split_group][1]*10_000).round.to_f / 10_000, 
                        (split_results[:middle_split_group][1]*10_000).round.to_f / 10_000]
    array_of_confidences.should == [0.9993, 0.8957]
  end
  it "should return adjusted G-test statistics for small success sizes" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 25], 
      :loosing_split_group => [1000, 5], #should be adjusted to [1000, minimum]
      :middle_split_group  => [1000, 15]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    split_results = predetermined_gtest.compare_split_groups
    array_of_g_stats = [(split_results[:loosing_split_group][0]*10_000).round.to_f / 10_000, 
                        (split_results[:middle_split_group][0]*10_000).round.to_f / 10_000]
    array_of_g_stats.should == [5.8595, 2.0838]

  end
  it "should return adjusted confidences for small success sizes" do
    sample_predetermined_gtest = {
      :winning_split_group => [1000, 25], 
      :loosing_split_group => [1000, 5], #should be adjusted to [1000, minimum]
      :middle_split_group  => [1000, 15]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    split_results = predetermined_gtest.compare_split_groups
    array_of_confidences = [(split_results[:loosing_split_group][1]*10_000).round.to_f / 10_000, 
                            (split_results[:middle_split_group][1]*10_000).round.to_f / 10_000]
    array_of_confidences.should == [0.9845, 0.8511]

  end
  it "should return a 0 G-test statistic for really small tests" do
    sample_predetermined_gtest = {
      :winning_split_group => [11, 5], 
      :loosing_split_group => [12, 3], #should be adjusted to [1000, minimum]
      :middle_split_group  => [13, 4]}
    predetermined_gtest = GTest.new sample_predetermined_gtest
    split_results = predetermined_gtest.compare_split_groups
    array_of_confidences = [(split_results[:loosing_split_group][1]*10_000).round.to_f / 10_000, 
                            (split_results[:middle_split_group][1]*10_000).round.to_f / 10_000]
    array_of_confidences.should == [0.0, 0.0]
  end
  it "should not allow the creation of a split test with less than two split groups" do
    sample_gtest = generate_gtest_scenario(1)
    lambda { broken_gtest = GTest.new sample_gtest }.should raise_error(GTestException)  
  end
  it "should properly calculate expected measures (private method)" do
    sample_gtest = generate_gtest_scenario(2)
    gtest = GTest.new sample_gtest
    priv_expected = gtest.send(:g_statistic_expected, 255.5, 200.0)
    ((priv_expected*10_000).round.to_f / 10_000).should == 62.5732
  end
end

