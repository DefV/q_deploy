configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	def _cset(name, *args, &block)
		unless exists?(name)
			set(name, *args, &block)
		end
	end

	def stage
		fetch(:stage, :integration).to_sym
	end

	def integration?
		stage == :integration
	end

	require 'railsless-deploy'
	require 'capistrano/ext/multistage'

	_cset :stages, %w(integration production)
	_cset :default_stage, "integration"

	_cset(:branch) {integration? ? "master" : "stable"}

	_cset :user, "sites"
	_cset :scm, 'git'

	_cset(:deploy_to){"/home/#{user}/apps/#{application}"}

	_cset :use_sudo, false
	_cset :group_writable, false
	_cset :keep_releases, 3
	_cset :deploy_via, :remote_cache

	_cset :git_shallow_clone, 1
	_cset :git_enable_submodules, 1
	_cset :ssh_options, {:forward_agent => true}

	_cset :user, "sites"
	role(:app) {integration? ? "vmma-001.openminds.be" : ["web-001.vmma.openminds.be", "web-002.vmma.openminds.be", "web-003.vmma.openminds.be"]}
	role(:web) {integration? ? "vmma-001.openminds.be" : ["web-001.vmma.openminds.be", "web-002.vmma.openminds.be", "web-003.vmma.openminds.be"]}
end