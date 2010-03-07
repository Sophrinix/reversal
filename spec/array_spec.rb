require 'spec_helper'

class A
  def uses_a_constant_array
    [1, 2, 3]
  end
  
  def builds_a_constant_array
    [1, 2, "three"]
  end
  
  def slightly_tricker_array(z)
    [x, y, z]
  end
  
  def splatted_array(arr)
    [*arr, 1, 2]
  end

end

describe "Method Reversal" do
  before do
    @uses_a_constant_array = DecompilationTestCase.new(A, :uses_a_constant_array, <<-EOF)
def uses_a_constant_array
  [1, 2, 3]
end
EOF
    @builds_a_constant_array = DecompilationTestCase.new(A, :builds_a_constant_array, <<-EOF)
def builds_a_constant_array
  [1, 2, "three"]
end
EOF
    @slightly_tricker_array = DecompilationTestCase.new(A, :slightly_tricker_array, <<-EOF)
def slightly_tricker_array(z)
  [x, y, z]
end
EOF
  
    # not yet an optimal decompilation
    @splatted_array = DecompilationTestCase.new(A, :splatted_array, <<-EOF)
def splatted_array(arr)
  (arr + [1, 2])
end
EOF

  end

  it "can decompile an array of constants" do
    @uses_a_constant_array.assert_correct
  end
  
  it "can build an array of different types" do
    @builds_a_constant_array.assert_correct
  end
  
  it "can build with method calls and local variables" do
    @slightly_tricker_array.assert_correct
  end
  
  it "can handle an array splatted into a literal array" do
    @splatted_array.assert_correct
  end
end