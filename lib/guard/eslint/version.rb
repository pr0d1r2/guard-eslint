module Guard
  # A workaround for some superclass BS
  # where Eslint < Guard has to exist?
  module EslintVersion
    # http://semver.org/
    MAJOR = 1
    MINOR = 1
    PATCH = 0

    def self.to_s
      [MAJOR, MINOR, PATCH].join('.')
    end
  end
end
