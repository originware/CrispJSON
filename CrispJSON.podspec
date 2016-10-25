Pod::Spec.new do |s|
  s.name             = 'CrispJSON'
  s.version          = '1.0.1'
  s.summary          = 'Create concise and readable JSON parsers with CrispJSON.'
  s.homepage    	  = "https://bitbucket.org/originware/crispjson"
  s.license          = { :type => "Apache 2.0" }
  s.author           = { 'Terry Stillone' => 'terry@originware.com' }
  s.description      = <<-DESC
CrispJSON allows you to create concise and readable JSON parsing code in Swift. Scalable and lightweight, it parses both simple and complex JSON.
                       DESC
  s.requires_arc = true
  s.osx.deployment_target = "10.9"
  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source   = { :git => "https://originware@bitbucket.org/originware/crispjson.git", :tag => s.version }
  s.source_files = "CrispJSON/Sources/**/*.swift"
end
