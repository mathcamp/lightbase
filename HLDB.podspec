Pod::Spec.new do |s|
  s.name = 'hldb'
  s.version = '1.0'
  s.license = 'MIT'
  s.summary = 'A Swifty database wrapper around FMDB'
  s.homepage = 'https://github.com/mathcamp/hldb'
  s.social_media_url = ''
  s.authors = { 'Ben Garret' => 'bag@highlig.ht', "Andrew Breckenridge" => "asbreckenridge@me.com" }
  s.source = { :git => 'https://github.com/mathcamp/hldb.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '8.0'

  s.source_files = 'hldb/*.swift'

  s.dependency 'FMDB'
  s.dependency 'BrightFutures'

  s.requires_arc = true
end
