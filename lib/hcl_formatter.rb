# Format Ruby values as HCL syntax for use in ERB templates
module HclFormatter
  def hcl_list(items)
    if items.size == 1
      "[#{items.first.inspect}]"
    else
      entries = items.map { |i| "    #{i.inspect}" }.join(",\n")
      "[\n#{entries}\n  ]"
    end
  end
end
