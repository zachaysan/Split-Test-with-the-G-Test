
require 'chi_prob.rb'

class GTestException < Exception
end

class GTest
  attr_accessor :min_successes, :yates
  
  #split_groups.form? => split_group[:a_split_group] = [trails, successes]
  def initialize(split_groups, min_successes=10.0, yates=:on)
    raise "GTest expects a hash of split groups" unless split_groups.is_a? Hash
    raise GTestException.new("need at least two split tests") if split_groups.size < 2
    @min_successes = min_successes
    @split_groups = split_groups
    @yates = yates
  end
  def assure_format
    @split_groups.each do |split_group, measures|
      raise GTestException.new("GTest expects a nested array of measures") unless measures.is_a? Array 
    end
  end
  def find_best_performing
    assure_format
    current_group, best_group_so_far = 0.0, 0.0
    @split_groups.each do |split_group, measure|
      current_group = measure[1].to_f/measure[0]
      if current_group > best_group_so_far
        best_group_so_far = current_group
        @best_performing_group = split_group
      end
    end
    @best_performing_group
  end
  def compare_split_groups
    # Returns a hash of results: split_group_results[split_group_name] = [g_stat, confidence]
    find_best_performing
    @split_group_results = {}
    g_stat, confidence = 0.0, 0.0
    @split_groups.each do |split_group, measure|
      g_stat, confidence = calculate_g(split_group, @best_performing_group) unless split_group == @best_performing_group
      @split_group_results[split_group] = [g_stat, confidence]
    end
    return @split_group_results
  end
  def ensure_minimum(winning_successes, winning_failures, other_successes, other_failures)
    # setting min failures to min successes is on purpose. 
    # I don't think it is worth confusing people over the difference
    # because most of the time people will worry about 
    # min_successes over min_failures
    @min_failures = @min_successes 
    custom_g_stat = nil
    custom_other_successes = other_successes
    if winning_successes < @min_successes or winning_failures < @min_failures 
      custom_g_stat = 0
    elsif other_failures < @min_failures
      custom_g_stat = 0
    elsif other_successes < @min_successes \
      and (other_successes + other_failures) > (@min_successes + @min_failures) \
      and (@min_successes / (other_failures + other_successes)) < \
      winning_successes / (winning_successes + winning_failures)
      custom_other_successes = @min_successes.to_f
    end
    return custom_g_stat, custom_other_successes
  end
  def calculate_g(other_group, winning_group)
    winning_trials = @split_groups[winning_group][0].to_f
    winning_successes = @split_groups[winning_group][1].to_f
    winning_failures = winning_trials - winning_successes

    other_trials = @split_groups[other_group][0].to_f
    other_successes = @split_groups[other_group][1].to_f
    other_failures = other_trials - other_successes

    g_statistic, other_successes = ensure_minimum(winning_successes, winning_failures, other_successes, other_failures)
    other_failures = other_trials - other_successes
    
    total_trials = winning_trials + other_trials
    total_successes = winning_successes + other_successes
    total_failures = winning_failures + other_failures

    expected_winning_successes = winning_trials.to_f * total_successes / total_trials
    expected_winning_failures = winning_trials.to_f * total_failures / total_trials
    expected_other_successes = other_trials.to_f * total_successes / total_trials
    expected_other_failures = other_trials.to_f * total_failures / total_trials
    
    winning_successes = yates_correct(winning_successes, expected_winning_successes)
    winning_failures = yates_correct(winning_failures, expected_winning_failures)
    other_successes = yates_correct(other_successes, expected_other_successes)
    other_failures = yates_correct(other_failures, expected_other_failures)

    if g_statistic.nil?
      g_statistic = 2 * ( g_statistic_expected(winning_successes, expected_winning_successes) + \
                          g_statistic_expected(winning_failures, expected_winning_failures) + \
                          g_statistic_expected(other_successes, expected_other_successes) + \
                          g_statistic_expected(other_failures, expected_other_failures))
    end

    chi_prob = Chi_Prob.new
    confidence = 1 - (chi_prob.calculate_new_x g_statistic)
    return g_statistic, confidence
  end
  def yates_correct(actual, expected)
    # the purpose of the yates_correction is to adjust for the fact that most
    # measurements are discrete, so there is an inherient bias towards the mean
    # that usually needs to be corrected for. 
    if @yates == :on
      if expected + 0.5 < actual
        actual -= 0.5
      elsif expected - 0.5 > actual
        actual += 0.5
      else
        actual = expected
      end
    end
    actual
  end

  private
  def g_statistic_expected(group_measure, expected_group_measure)
    return group_measure * Math::log(group_measure / expected_group_measure)
  end
end

#aliases for forgetful users
class Gtest < GTest
end
