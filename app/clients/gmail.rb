class Gmail
  def initialize
    email ||= ENV["GMAIL_ADDRESS"] || "stadia@gmail.com"
    password ||= ENV["GMAIL_PASSWORD"]

    Mail.defaults do
      retriever_method :imap, address: "imap.gmail.com",
                              port: 993,
                              user_name: email,
                              password: password,
                              enable_ssl: true
    end
    Rails.logger.debug "Gmail 클라이언트 초기화: #{conn}"
  end

  def fetch_emails(options = {})
    sender = options[:from] || "rubyonrails@maily.so"
    since_date = options[:since] || 1.month.ago

    # IMAP 검색 쿼리를 명시적으로 구성
    query = "FROM \"#{sender}\""
    # 날짜 필터링 추가
    if since_date
      # IMAP 날짜 형식으로 변환 (DD-MMM-YYYY)
      formatted_date = since_date.strftime("%d-%b-%Y")
      query += " SINCE \"#{formatted_date}\""
    end
    Rails.logger.debug "IMAP 검색 쿼리: #{query}"

    emails = Mail.find(order: :desc, keys: query)
    Rails.logger.info "검색된 이메일 수: #{emails.length}"
    emails
  end
end
