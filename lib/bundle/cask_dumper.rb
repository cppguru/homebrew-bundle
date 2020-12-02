# frozen_string_literal: true

module Bundle
  module CaskDumper
    module_function

    def reset!
      @casks = nil
    end

    def casks
      return [] unless Bundle.cask_installed?

      @casks ||= `brew list --cask 2>/dev/null`.split("\n")
      @casks.map { |cask| cask.chomp " (!)" }
            .uniq
    end

    def dump(casks_required_by_formulae)
      [
        (casks & casks_required_by_formulae).map { |cask| "cask \"#{cask}\"" }.join("\n"),
        (casks - casks_required_by_formulae).map { |cask| "cask \"#{cask}\"" }.join("\n"),
      ]
    end

    def formula_dependencies(cask_list)
      return [] if cask_list.blank?

      cask_info_command = "brew info --cask --json=v2"
      cask_info_response = `#{cask_info_command}`
      cask_info = JSON.parse(cask_info_response)

      cask_info["casks"].flat_map do |cask|
        cask.dig("depends_on", "formula")
      end.compact.uniq
    rescue JSON::ParserError => e
      opoo "Failed to parse `#{cask_info_command}`:\n#{e}"
      []
    end
  end
end
