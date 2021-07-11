desc 'message consumer'
task :consumer => :environment do
  puts "=> starting consumer"

  MQ::ClientSingleton.subscribe("crm", 'alert') do |delivery_info, properties, content|
    puts content
  end
end
