spec = Gem::Specification.new do |s|
  s.name = "cloud-crawler"
  s.version = "0.1"
  s.author = "Charles H. Martin, PhD"
  s.homepage = "http://calculatedcontent.com"
  s.rubyforge_project = "cloud-crawler"
  s.platform = Gem::Platform::RUBY
  s.summary = "Cloud Crawler distributed web-spider framework"
  s.executables = %w[start_batch_crawl.rb run_worker.rb] 
  s.require_path = "lib"
  s.has_rdoc = false
  s.rdoc_options << '-m' << 'README.rdoc' << '-t' << 'CloudCrawler'
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_dependency "nokogiri", ">= 1.5.6"
  s.add_dependency "robotex", ">= 1.0.0"
  s.add_dependency "redis", ">=3.0.3"   
  s.add_dependency "redis-namespace", ">=1.2.1"
  s.add_dependency "bloomfilter-rb", ">=2.1.1"
  s.add_dependency "hiredis", "~> 0.4.5"
  s.add_dependency "active_support", "~> 3.0.0"
  s.add_dependency "webrick", "~> 1.3.1"
  s.add_dependency "trollop"
  s.add_dependency "bson_ext", ">=1.3.1"
  s.add_dependency "i18n", ">=0.6.4"
  s.add_dependency "iconv", ">=1.0.3"
  s.add_dependency "httparty"
  s.add_dependency "thin"   # for qless-web
  
  # s.add_dependency "qless", ">=0.9.2"  # cc version
  # s.add_dependency "sourcify", ">=0.6.0.rc3"  # cc version

  s.add_development_dependency "rake", ">=10.0.0"
  s.add_development_dependency "rspec", ">=2.12.0"
  s.add_development_dependency "fakeweb", ">=1.3.0"
 


  s.files = %w[
    VERSION
    LICENSE
    INSTALL.aws.rdoc
    INSTALL.local.rdoc
    CHANGELOG.rdoc
    README.rdoc
    Rakefile
  ] + Dir['lib/**/*.rb']

  s.test_files = Dir['spec/*.rb']
end
