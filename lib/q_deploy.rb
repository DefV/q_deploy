configuration = Capistrano::Configuration.respond_to?(:instance) ? Capistrano::Configuration.instance(:must_exist) : Capistrano.configuration(:must_exist)

configuration.load do
	def _cset(name, *args, &block)
		unless exists?(name)
			set(name, *args, &block)
		end
	end

	def current_stage
		fetch(:stage, :integration).to_sym
	end

	def integration?
		current_stage == :integration
	end

	def shared_storage(path)
		links = fetch(:shared_storage_paths, [])
		links << path
		set :shared_storage_paths, links

		before "deploy:finalize_update", "q_shared_storage:link"
		after "deploy:setup", "q_shared_storage:setup"
	end

	def drush(cmd)
		drush = fetch(:drush, "drush")
		run "cd #{drupal_path} && #{drush} #{cmd}"
	end

	namespace :q_shared_storage do
		desc "Link shared storage."
		task :link do
			return if integration?
			fetch(:shared_storage_paths, []).each do |path|
				run "rm -rf #{release_path}/#{path}"
				run "ln -nfs /dist/apps/#{application}/#{path} #{release_path}/#{path}"
			end
		end

		task :setup do
			return if integration?
			fetch(:shared_storage_paths, []).each do |path|
				run "mkdir -p /dist/apps/#{application}/#{path}"
			end
		end 
	end

	namespace :drupal do
		desc "Run drush commands"

		task :cca, :roles => :db do
			drush "cc all"
		end

		task :fra, :roles => :db do
			drush "-y fra"
		end

		task :updb, :roles => :db do
			drush "-y updb"
		end
	end
	
	_cset :stages, %w(integration production)
	_cset :default_stage, "integration"
	_cset(:drupal_path) {release_path}

	_cset(:branch) {integration? ? "master" : "production"}

	set :scm, 'git'

	set(:deploy_to){"/home/#{user}/apps/#{application}"}

	_cset :use_sudo, false
	_cset :group_writable, false
	_cset :keep_releases, 3
	_cset :deploy_via, :remote_cache

	_cset :git_shallow_clone, 1
	set :ssh_options, {:forward_agent => true}
	default_run_options[:pty] = true

	_cset :user, "sites"
	role(:app) {integration? ? "dev-001.vmma.openminds.be" : ["web-001.vmma.openminds.be", "web-002.vmma.openminds.be", "web-003.vmma.openminds.be"]}
	role(:web) {integration? ? "dev-001.vmma.openminds.be" : ["web-001.vmma.openminds.be", "web-002.vmma.openminds.be", "web-003.vmma.openminds.be"]}
	role(:db) {integration? ? "dev-001.vmma.openminds.be" : "web-001.vmma.openminds.be"}

	require 'railsless-deploy'
	require 'capistrano/ext/multistage'

	stages.each do |stage|
		task(stage) do
			set :stage, stage.to_sym
		end
	end	
end