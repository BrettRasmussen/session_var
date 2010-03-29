namespace :radiant do
  namespace :extensions do
    namespace :session_var do
      
      desc "Runs the migration of the SessionVar extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          SessionVarExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          SessionVarExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the SessionVar to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from SessionVarExtension"
        Dir[SessionVarExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(SessionVarExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end
