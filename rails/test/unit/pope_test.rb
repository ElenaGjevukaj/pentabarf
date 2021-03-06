require File.dirname(__FILE__) + '/../test_helper'

class PopeTest < Test::Unit::TestCase

  def setup
    POPE.send( :instance_variable_set, :@user, Pope::User.new( Account.select_single(:login_name=>'testcase_norole') ))
  end

  def test_single_domain_permissions
    chunky = Person.new
    chunky.public_name = 'Chunky Bacon'
    assert_raise( Pope::PermissionError ) { chunky.write }

    POPE.instance_eval{ @permissions = [:'person::create'] }
    assert_nothing_raised{ chunky.write }
    assert_raise( Pope::PermissionError ) { chunky.delete }

    POPE.instance_eval{ @permissions = [:'person::delete'] }
    assert_nothing_raised{ chunky.delete }
  end

end
