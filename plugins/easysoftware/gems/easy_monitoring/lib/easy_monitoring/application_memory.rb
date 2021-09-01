module EasyMonitoring
  class ApplicationMemory
    class << self

      def usage
        memory = usage_by_proc || usage_by_ps
        raise "Unable to get memory consuming using `ps -o rsz #{process}` and RSS in #{proc_status_file}" unless memory

        memory.round(2)
      end

      private

      # get application ram size using linux command `ps`
      def usage_by_ps
        memory = cmd("ps -o rsz #{process}").split("\n")[1].to_f / 1.kilobyte
        return nil if memory <= 0

        memory
      end

      # get application ram size using linux proc status
      def usage_by_proc
        return nil unless File.exist? proc_status_file

        proc_status = File.open(proc_status_file, "r") { |f| f.read_nonblock(4096).strip }
        if (m = proc_status.match(/RSS:\s*(\d+) kB/i))
          m[1].to_f / 1.kilobyte
        end
      end

      def process
        $$
      end

      def proc_status_file
        "/proc/#{process}/status"
      end

      # @param [String] command
      # @return [String]
      def cmd(command)
        `#{command}`.strip
      rescue StandardError
        ""
      end

    end
  end
end
