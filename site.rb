description 'Stack template for my blog'

ROOT_DNS = "tilmonedwards.com"

A_RECORDS = {
  "@" => "192.30.252.153",
  "*" => "104.131.240.227"
}

CNAME_RECORDS = {
  "www" => "tilmonedwards.com",
  "farm" => "notsorandom.com",
  "feeds" => "1kgl0md.feedproxy.ghs.google.com",
  "static" => "static.tilmonedwards.com.s3-website-us-east-1.amazonaws.com"
}

resource :HostedZone, 'AWS::Route53::HostedZone' do
  name ROOT_DNS
  hosted_zone_config "Comment" => "Root domain"
end

resource :StaticS3, "AWS::S3::Bucket" do
  bucket_name "static.tilmonedwards.com"
  access_control :PublicRead
  website_configuration :IndexDocument => "index.html",
    :ErrorDocument => "404.html"
end

resource :StaticS3Policy, "AWS::S3::BucketPolicy" do
  bucket "static.tilmonedwards.com"
  policy_document "Version" => "2012-10-17",
    "Statement" => [
      {
        "Sid" => "AddPerm",
        "Effect" => "Allow",
        "Principal" => "*",
          "Action" => ["s3:GetObject"],
          "Resource" => [ "arn:aws:s3:::static.tilmonedwards.com/*" ]
      }
    ]
end

resource :GoogleApps, 'AWS::Route53::RecordSetGroup' do
  hosted_zone_id Fn::ref(:HostedZone)
  record_sets [
    {
      "Name" => ROOT_DNS,
      "Type" => "MX",
      "TTL" => 60,
      "ResourceRecords" => [
        "1 aspmx.l.google.com.",
        "5 alt1.aspmx.l.google.com.",
        "5 alt2.aspmx.l.google.com.",
        "10 alt3.aspmx.l.google.com.",
        "10 alt4.aspmx.l.google.com.",
      ]
    },
    {
      "Name" => ROOT_DNS,
      "Type" => "TXT",
      "TTL" => 600,
      "ResourceRecords" => [
        '"google-site-verification=UKEUBSGk5oPXN3rNazqzmAtMY6M-5NnOvVoDHpbbew8"',
        '"v=spf1 include:_spf.google.com ~all"'
      ]
    }
  ]
end

resource :DNSRecords, "AWS::Route53::RecordSetGroup" do
  hosted_zone_id Fn::ref(:HostedZone)
  record_sets A_RECORDS.keys.map { |k|
    {
      "Name" => (k == "@" ? "#{ROOT_DNS}." : "#{k}.#{ROOT_DNS}."),
      "Type" => "A",
      "TTL" => 60,
      "ResourceRecords" => [ A_RECORDS[k] ]
    }
  } + CNAME_RECORDS.keys.map { |k|
    {
      "Name" => "#{k}.#{ROOT_DNS}.",
      "Type" => "CNAME",
      "TTL" => 60,
      "ResourceRecords" => [ CNAME_RECORDS[k] ]
    }
  }
end
