Pod::Spec.new do |s|
  s.name             = 'ComposableArchitectureX'
  s.version          = '0.1.0'
  s.summary          = 'ComposableArchitectureX.'

  s.description      = <<-DESC
  The ComposableArchitectureX is a library implement TCA to support iOS9.0+.
                       DESC

  s.homepage         = 'https://github.com/scardadfs/ComposableArchitectureX'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sylva' => 'fssfkg@163.com' }
  s.source           = { :git => 'https://github.com/scardadfs/ComposableArchitectureX.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'ComposableArchitectureX/Classes/**/*'
  s.dependency "RxSwift", "~> 5.0"
end
J
