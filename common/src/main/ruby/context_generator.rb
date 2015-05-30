#!/bin/ruby
require 'json'
require 'nokogiri'
require_relative 'common'

conn = createPGConn()

##############################################################################
# Hopefully only thing you have to edit
##############################################################################
BEAN_DIRECTORY = ROOT+'/'+DNSS['web.webinf_path']

##############################################################################
# gets all the jobs [write]
# notes:
#   jobnumber => 0 = base, 1 = first advancement, etc.
#   maxspjobx => # ratio to max SP (floored); at the moment 3 and 4 are unused
##############################################################################
jobs = Hash.new
query = <<sql_query
  SELECT j._id,
         m._data as jobname,
         LOWER(_englishname) as identifier,
         _jobnumber as advancement,
         _parentjob,
         _maxspjob0, _maxspjob1, _maxspjob2
  FROM jobs j
  INNER JOIN messages m
    ON _jobname = m._id
  WHERE _service is TRUE
  ORDER BY _id ASC
sql_query

conn.exec(query).each_dnt do |job|
  job['skilltree'] = Array.new
  jobs[job['id']] = job
  job['spRatio'] = [job['maxspjob0'], job['maxspjob1'], job['maxspjob2']]
  ['maxspjob0', 'maxspjob1', 'maxspjob2'].each {|a| job.delete(a)}
  jobs[job['id']].delete('id')
end

##############################################################################
# get the skill tree for each class
##############################################################################
query = <<sql_query
  SELECT _needjob,
         _skilltableid as skillid,
         _treeslotindex
  FROM skill_tree
  INNER JOIN skills
    ON _skilltableid = skills._id
sql_query
conn.exec(query).each_dnt do |tree|
  job = jobs[tree['needjob']]
  job['skilltree'][tree['treeslotindex']] = tree['skillid']
end


##############################################################################
# generate the bean file
##############################################################################
builder = Nokogiri::XML::Builder.new do |xml|
  xml.beans(SPRING_BEAN_HEADER) do
    xml.import('resource' => 'levels-context.xml')
    xml.import('resource' => 'types-context.xml')
    xml.import('resource' => 'skills-context.xml')

    jobs.each_value do |job|
      job['skilltree'] = job['skilltree'].skilltree_partition()

      xml.bean('id' => 'job_' + job['identifier'], 'class' => 'dnss.model.Job', 'scope' => 'prototype') do # create job only if needed
        xml.property('name' => 'name', 'value' => job['jobname'])
        xml.property('name' => 'identifier', 'value' => job['identifier'])
        xml.property('name' => 'advancement', 'value' => job['advancement'])
        xml.property('name' => 'parent', 'ref' => 'job_' + jobs[job['parentjob']]['identifier']) unless job['parentjob'] == 0
        xml.property('name' => 'spRatio') {xml.list {job['spRatio'].each {|spRatio| xml.value_ spRatio}}}
        xml.property('name' => 'skillTree') do
          xml.list do
            job['skilltree'].each do |skillblock|
              xml.list('value-type' => 'dnss.model.Skill') do 
                skillblock.each do |skill|
                  if skill.to_i == 0
                    xml.null_
                  else
                    xml.ref('bean' => "skill_#{skill}")
                  end
                end
              end
            end
          end
        end
      end
    end

    jobs.select {|id, job| job['advancement'] == 2}.each_value do |job|
      xml.bean('id' => 'jobs_' + job['identifier'], 'class' => 'dnss.model.Jobs', 'scope' => 'prototype') do # make it on an as needed basis
        xml.property('name' => 'primary', 'ref' => 'job_' + jobs[jobs[job['parentjob']]['parentjob']]['identifier'])
        xml.property('name' => 'secondary', 'ref' => 'job_' + jobs[job['parentjob']]['identifier'])
        xml.property('name' => 'tertiary', 'ref' => 'job_' + job['identifier'])
      end
    end

    adv = ['primary', 'secondary', 'tertiary']
    (0..2).each do |a|
      xml['util'].list('id' => 'all_jobs_%s' % adv[a], 'value-type' => 'dnss.model.Job', 'scope' => 'singleton') do # should have 1 of this with its own unadulterated job
        jobs.select {|id, job| job['advancement'] == a}.each_value do |job|
          xml.ref('bean' => 'job_' + job['identifier'])
        end
      end
    end
  end
end

BEAN_DIRECTORY.gsub!(/[\/\\]/, "/")
mkdir_p(BEAN_DIRECTORY)

##############################################################################
# WRITE: Bean
##############################################################################
path = '%s/%s.xml' % [BEAN_DIRECTORY, 'spring-context']
stream = open(path, 'w')
stream.write(builder.to_xml)
stream.close()

puts "%s has been created." % path

conn.close()

