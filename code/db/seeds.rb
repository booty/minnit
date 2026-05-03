member_names = %w[alice bob charlie dana eve frank grace henry iris jake]

members = member_names.map do |name|
  Member.find_or_create_by!(email: "#{name}@example.com") do |m|
    m.display_name = name
    m.password     = "weeb?666"
  end
end

forum_names = %w[ruby rails gamedev linux webdev security learnprogramming devops datascience offbeat]

forum_names.each do |name|
  Forum.find_or_create_by!(name: name) do |f|
    f.created_by_member = members.first
  end
end

puts "Seeded #{Member.count} members and #{Forum.count} forums."
