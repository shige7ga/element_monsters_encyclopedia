if Rails.env.production?
  require "bcrypt"

  [10, 11, 12].each do |cost|
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    BCrypt::Password.create("benchmark", cost: cost)

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

    Rails.logger.info "[BCRYPT BENCHMARK] cost=#{cost}: #{elapsed.round(3)}s"
  end
end
