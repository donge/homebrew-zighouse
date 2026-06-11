class Zighouse < Formula
  desc "ClickHouse-compatible columnar OLAP engine"
  homepage "https://github.com/donge/zighouse"
  license "MIT"
  head "https://github.com/donge/zighouse.git", branch: "main"

  stable do
    url "https://github.com/donge/zighouse/archive/refs/tags/v1.0.0.tar.gz"
    sha256 "97b03a5fdc46773ca4ba3eaa5ca31dae4cd5e98c88adf30a9e31989bbbd2d8b7"
  end

  depends_on "zig" => :build
  uses_from_macos "zlib"

  def install
    target = "#{Hardware::CPU.arch}-#{OS.kernel_name.downcase}"
    target = "x86_64-linux-gnu" if OS.linux? && Hardware::CPU.intel?
    target = "aarch64-linux-gnu" if OS.linux? && Hardware::CPU.arm?
    target = "aarch64-macos" if OS.mac? && Hardware::CPU.arm?
    target = "x86_64-macos" if OS.mac? && Hardware::CPU.intel?

    system "zig", "build",
      "-Dtarget=#{target}",
      "-Doptimize=ReleaseFast",
      "-Dstrip=true",
      "-Dstatic-libs=true"

    bin.install "zig-out/bin/zighouse"
  end

  service do
    run [opt_bin/"zighouse", "serve",
         "--data-dir=#{var}/zighouse",
         "--port=19902"]
    keep_alive true
    log_path var/"log/zighouse.log"
    error_log_path var/"log/zighouse.log"
  end

  test do
    port = free_port
    data_dir = testpath/"data"
    data_dir.mkpath
    pid = spawn bin/"zighouse", "serve", "--data-dir=#{data_dir}", "--port=#{port}"
    begin
      sleep 1
      assert_equal "1\n",
        shell_output("curl -s --noproxy localhost " \
                     "'http://127.0.0.1:#{port+1}/?query=SELECT+1' | tail -1")
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
