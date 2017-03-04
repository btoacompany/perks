data = {
 name: "test_#{Time.now.to_i}",
 email: "test_#{Time.now.to_i}@email.com",
}

t = Test.new
t.save_record(data)
