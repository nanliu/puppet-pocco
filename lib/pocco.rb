require 'rake'
require 'rocco'
require 'ruby-debug'

# Reopen rocco and put in some Puppet specific hacks.
class Rocco
  def split(sections)
    docs_blocks, code_blocks = [], []
    sections.each do |docs,code|
      header = []
      params = []
      usages = []
      process = false

      code_blocks << code.map do |line|
        container, name = parse_header(line)
        if container
          process = true
          header << ["### #{container.capitalize}: #{name}", ""]
          usages = test_file
        else
          param = parse_params(line)
          if process and param
            default = "(default: #{param[:default]})" if param[:default]
            params.push " * [*#{param[:name]}*]: #{param[:comment]} #{default}"
            line = param[:line]
          else
            process = false
          end
        end
        tabs = line.match(/^(\t+)/)
        tabs ? line.sub(/^\t+/, '  ' * tabs.captures[0].length) : line
      end.join("\n")
      params =  ["### Parameters:", ""] + params + [""] unless params.empty?
      docs = header + docs + params + usages
      docs_blocks << docs.join("\n")
    end
    [docs_blocks, code_blocks]
  end

  def test_file
    usages = []
    test_file = @file.gsub(/manifests\//, 'tests/')
    if File.exists? test_file
      usages = File.read(test_file).split("\n")
      usages = usages.collect{|line| "    #{line}"}
      usages = ["### Usage:", ""] + usages + [""]
    end
    usages
  end

  def parse_header(line)
    [ $1, $2 ] if line =~ /^\s*(class|define)\s+([\S]+?)\s*[\{\(]/
  end

  def parse_params(line)
    if line =~ /^\s*\$(\w+)/
      line, comment = line.split('#:')
      line =~ /^\s*\$(\S+)\s*[=]?\s*(\S+)?\s*/

      { :name    => $1.chomp(','),
        :default => ($2 || '').chomp(','),
        :comment => comment,
        :line    => line,
      }
    end
  end
end

class Pocco
  def initialize(module_path, options={})
    @sources = Rake::FileList[File.join(module_path,'manifests/**/*.pp')]
    @options = options
  end

  def generate
    @sources.each do |source_file|
      dest_file = source_file.sub(Regexp.new("#{File.extname(source_file)}$"), ".html")
      dest_file.sub!(/manifests\//, 'docs/')

      rocco = Rocco.new(source_file, @sources.to_a, @options)
      dest_dir = File.dirname(dest_file)
      FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
      File.open(dest_file, 'wb') { |fd| fd.write(rocco.to_html) }
    end
  end
end
