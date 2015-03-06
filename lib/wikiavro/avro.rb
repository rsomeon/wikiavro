require 'avro'

module WikiAvro::Avro
  NAMESPACE_SCHEMA = <<-EOS
{
  "namespace": "org.rationalwiki",
  "name": "Namespace",
  "type": "record",
  "fields": [
    {"name": "key", "type": "int"},
    {"name": "case", "type": "string"},
    {"name": "name", "type": "string"}
  ]
}
EOS

  PAGE_SCHEMA = <<-EOS
{
  "namespace": "org.rationalwiki",
  "name": "Page",
  "type": "record",
  "fields": [
    {"name": "id", "type": "long"},
    {"name": "ns", "type": "long"},
    {"name": "title", "type": "string"},
    {"name": "redirect", "type": ["null", "string"]},
    {"name": "sha1", "type": ["null", "string"]}
  ]
}
EOS

  REVISION_SCHEMA = <<-EOS
{
  "namespace": "org.rationalwiki",
  "name": "Revision",
  "type": "record",
  "fields": [
    {"name": "id", "type": "long"},
    {"name": "page_id", "type": "long"},
    {"name": "n", "type": "long"},
    {"name": "timestamp", "type": "string"},
    {"name": "contributor", "type": ["null", {
      "namespace": "org.rationalwiki",
      "name": "Contributor",
      "type": "record",
      "fields": [
	{"name": "id", "type": ["null", "long"]},
	{"name": "username", "type": ["null", "string"]},
	{"name": "ip", "type": ["null", "string"]}
      ]
    }]},
    {"name": "minor", "type": "boolean"},
    {"name": "comment", "type": ["null", "string"]},
    {"name": "bytes", "type": "long"},
    {"name": "textid", "type": ["null", "string"]},
    {"name": "text", "type": ["null", "string"]}
  ]
}
EOS

  LQT_SCHEMA = <<-EOS
{
  "namespace": "org.rationalwiki",
  "name": "Threading",
  "type": "record",
  "fields": [
    {"name": "subject", "type": "string"},
    {"name": "parent", "type": ["null", "long"]},
    {"name": "ancestor", "type": ["null", "long"]},
    {"name": "page", "type": "string"},
    {"name": "id", "type": "long"},
    {"name": "summary_page", "type": ["null", "string"]},
    {"name": "author", "type": "string"},
    {"name": "edit_status", "type": "string"},
    {"name": "type", "type": "string"},
    {"name": "signature", "type": ["null", "string"]}
  ]
}
EOS

  class AvroWriter
    def schema
      raise NotImplementedError
    end

    def close
      @writer.close
    end

    protected

    def encode(data)
      @writer << data
    end

    def initialize(path, deflate=false)
      if !deflate
        @writer = Avro::DataFile.open(path, 'w', schema)
      else
        @writer = Avro::DataFile.open(path, 'w', schema, 'deflate')
      end
    end
  end

  class NamespaceWriter < AvroWriter
    def schema
      NAMESPACE_SCHEMA
    end

    def write(key, casetype, name)
      encode 'key' => key.to_i,
             'case' => casetype,
             'name' => name || ''
    end
  end

  class PageWriter < AvroWriter
    def schema
      PAGE_SCHEMA
    end

    def write(ns, id, title, redirect, sha1)
      encode 'id' => id.to_i,
             'ns' => ns.to_i,
             'title' => title,
             'redirect' => redirect,
             'sha1' => sha1
    end
  end

  class RevisionWriter < AvroWriter
    def schema
      REVISION_SCHEMA
    end

    def write(id, page_id, n, timestamp, contributor, minor,
              comment, text_deleted, bytes, textid, text)
      if !contributor[:deleted].nil? && !(contributor[:id].nil? &&
                                          contributor[:username].nil? &&
                                          contributor[:ip].nil?)
        raise 'deleted contributor has content'
      end

      if contributor[:deleted].nil?
        contributor.delete :deleted
        contributor = {
          'username' => contributor[:username],
          'id' => contributor[:id].to_i,
          'ip' => contributor[:ip]
        }
      else
        contributor = nil
      end

      if comment[:deleted].nil?
        comment = comment[:comment]
      else
        raise 'deleted comment has content' if comment[:comment]
        comment = nil
      end

      text = nil if !text_deleted.nil?

      encode 'id' => id.to_i,
             'page_id' => page_id.to_i,
             'n' => n.to_i,
             'timestamp' => timestamp,
             'contributor' => contributor,
             'minor' => minor.nil?,
             'comment' => comment,
             'bytes' => bytes.to_i,
             'textid' => textid,
             'text' => text
    end
  end

  class LqtWriter < AvroWriter
    def schema
      LQT_SCHEMA
    end

    def write(subject, parent, ancestor, page, id, summary_page,
              author, edit_status, type, signature)
      parent = parent.to_i if parent
      ancestor = ancestor.to_i if ancestor

      encode 'subject' => subject,
             'parent' => parent,
             'ancestor' => ancestor,
             'page' => page,
             'id' => id.to_i,
             'summary_page' => summary_page,
             'author' => author,
             'edit_status' => edit_status,
             'type' => type,
             'signature' => signature
    end
  end
end
