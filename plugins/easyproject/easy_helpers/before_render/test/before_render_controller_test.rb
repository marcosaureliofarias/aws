require 'test_helper'

class SampleController < ActionController::Base
  before_action :action_one
  after_action :action_three
  before_render :action_two, :except => [:new]
  skip_before_render :action_two, :only => [:show]

  attr_accessor :actions

  def index; render :plain => ''; end
  def new;   render :plain => ''; end
  def show;  render :plain => ''; end

  def reset_actions
    @actions = ''
  end

  private
  def action_one
    @actions << 'a'
  end
  def action_two
    @actions << 'b'
  end
  def action_three
    @actions << 'c'
  end
end

class SampleControllerTest < ActionController::TestCase
  setup do
    @request.env['REQUEST_METHOD'] = 'GET'
    @request.action = 'index'

    @controller.reset_actions
  end

  def test_before_render_in_place
    with_routing do |set|
      set.draw do
        match ':controller(/:action)'
      end
      process :index
    end
    assert_equal @controller.actions, 'abc'
  end

  def test_before_render_except_option
    with_routing do |set|
      set.draw do
        match ':controller(/:action)'
      end
      process :new
    end
    assert_equal @controller.actions, 'ac'
  end

  def test_skip_before_render
    with_routing do |set|
      set.draw do
        match ':controller(/:action)'
      end
      process :show
    end
    assert_equal @controller.actions, 'ac'
  end

end
