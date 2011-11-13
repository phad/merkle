#!/usr/bin/env ruby
require 'digest/sha1'

class MerkleTree

  attr :nodes
  attr :blocks
  attr :block_size
  attr :root

  def initialize(block_size)
    reset
    end

  def add_line(line)
    @blocks << line
    if (@blocks.length == BLOCK_SIZE)
      nodes << Node.new(Digest::SHA1.hexdigest(@blocks.join()))
      @blocks = []
    end
  end

  def finish
    if (@blocks.length > 0)
      @nodes << Node.new(Digest::SHA1.hexdigest(@blocks.join()))
    end

    while (@nodes.length & (@nodes.length - 1)) != 0 do
      @nodes << Node.new('padding')
    end

    next_nodes = []
    while (next_nodes.length == 0) do
      add_level(@nodes, next_nodes)
      @nodes = next_nodes
      if (next_nodes.length > 1)
        next_nodes = []
      end
    end
    @root = next_nodes[0]
  end

  def output
    @root.output
    reset
  end

  def reset
    @nodes = []
    @blocks = []
    @block_size = block_size
    @root = nil
  end

  private

  class Node
    attr_accessor :hash, :parent
    def initialize(hash)
      @hash = hash
      @parent = nil
      @children = []
    end

    def add_child c
      @children << c
      c.parent = self
    end

    def output
      do_output(0)
    end

    def do_output(depth)
      depth.times { print ' ' }
      print "[#{@hash}] "
      if (@children.length > 0)
        print '{'
        puts
        @children.each { |child| child.do_output(depth + 1) }
        depth.times { print ' ' }
        print '}'
      end
      puts
    end
  end

  def make_pair(left, right)
    n = Node.new(Digest::SHA1.hexdigest("#{left.hash}||#{right.hash}"))
    n.add_child left
    n.add_child right
    n
  end

  def add_level(this_level, next_level)
    if (this_level.length == 1)
      next_level << this_level[0]
      return
    end
    prev = nil
    this_level.each do |node|
      if prev
        next_level << make_pair(prev, node)
        prev = nil
      else
        prev = node
      end
    end
    if prev
      next_level << make_pair(prev, Node.new('padding'))
    end
  end
end

BLOCK_SIZE = 32
mt = MerkleTree.new(BLOCK_SIZE)
ARGF.each { |line| mt.add_line(line) }
mt.finish
mt.output
