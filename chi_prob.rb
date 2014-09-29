require "statistics2"

class Chi_Prob
  def initialize
  end
  
  def calculate_new_x(x)
    x = 15.0 if x > 15
    @answer = 1.0 - Statistics2.chi2dist(1,x)
  end
  
  def get_answer
    return @answer
  end
end
