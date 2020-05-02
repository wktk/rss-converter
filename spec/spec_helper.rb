def fixture(path)
  File.open(File.join(File.dirname(__FILE__), 'fixtures', path))
end
