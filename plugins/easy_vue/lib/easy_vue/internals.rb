# Use this module for static methods
module EasyVue
  class NpmInstallError < StandardError
  end
  class NpmBuildError < StandardError
  end

  def self.compile
    raise NpmInstallError unless system "npm --no-audit --silent --no-progress --prefix plugins/easy_vue ci |> /dev/null"
    raise NpmBuildError unless system "npm --no-audit --silent --prefix plugins/easy_vue run build"
  end
end
