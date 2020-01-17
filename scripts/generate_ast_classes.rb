#!/usr/bin/env ruby

Type = Struct.new(:class_name, :fields)
Field = Struct.new(:type, :name)

def define_visitor(base_name, types)
  stream = StringIO.new

  stream.puts '  interface Visitor<R> {'

  types.each { |t|
    stream.puts "    R visit#{t.class_name}#{base_name}(#{t.class_name} #{base_name.downcase});"
  }

  stream.puts '  }'

  stream.string
end

def define_type(base_name, class_name, fields)
  stream = StringIO.new

  stream.puts "  static class #{class_name} extends #{base_name} {"

  # Fields.
  fields.each { |f|
    stream.puts("    final #{f.type} #{f.name};");
  }

  stream.puts

  # Constructor.
  constructor_fields = fields.map { |f|
    "#{f.type} #{f.name}"
  }.join(', ')
  stream.puts "    #{class_name}(#{constructor_fields}) {"

  # Store parameters in fields.
  fields.each { |f|
    stream.puts "      this.#{f.name} = #{f.name};"
  }

  stream.puts '    }';

  stream.puts

  # Visitor pattern implementation
  stream.puts '    @Override'
  stream.puts '    <R> R accept(Visitor<R> visitor) {'
  stream.puts "      return visitor.visit#{class_name}#{base_name}(this);"
  stream.puts '    }'

  stream.puts '  }'

  stream
end

def define_ast(output_dir, base_name, types)
  visitor_content = define_visitor(base_name, types)

  inner_classes = types.map { |type|
    define_type(base_name, type.class_name, type.fields)
  }

  inner_classes_content = inner_classes
    .map(&:string)
    .join("\n")
    .rstrip

  path = File.join(output_dir, base_name + ".java");
  File.write(path, <<~EOF)
package com.craftinginterpreters.lox;

import java.util.List;

abstract class #{base_name} {
#{visitor_content}
#{inner_classes_content}

  abstract <R> R accept(Visitor<R> visitor);
}
  EOF
end

if ARGV.count != 1
  puts "Usage: generate_ast <output directory>"
  exit 1
end

output_dir = ARGV.pop

define_ast(output_dir, "Expr", [
  Type.new('Binary', [ Field.new('Expr', 'left'), Field.new('Token', 'operator'), Field.new('Expr', 'right') ]),
  Type.new('Grouping', [ Field.new('Expr', 'expression') ]),
  Type.new('Literal', [ Field.new('Object', 'value') ]),
  Type.new('Unary', [ Field.new('Token', 'operator'), Field.new('Expr', 'right') ])
])
