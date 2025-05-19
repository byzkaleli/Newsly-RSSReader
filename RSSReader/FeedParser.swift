import Foundation

class FeedParser: NSObject, XMLParserDelegate {
    private var items: [RSSFeedItem] = [] //Toplanan haberler
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var completionHandler: (([RSSFeedItem]) -> Void)? //Parse işlemi bitince çağrılır

    //Tek bir URL'den RSS verisi çek
    func parseFeed(url: URL, completion: @escaping ([RSSFeedItem]) -> Void) {
        self.completionHandler = completion

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }.resume()
    }

    //Birden fazla RSS kaynağını paralel parse et
    func parseMultipleFeeds(urls: [String], completion: @escaping ([RSSFeedItem]) -> Void) {
        let group = DispatchGroup()
        var allItems: [RSSFeedItem] = []

        for urlString in urls {
            if let url = URL(string: urlString) {
                group.enter()
                parseFeed(url: url) { items in
                    allItems += items
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(allItems.sorted {
                ($0.pubDate ?? Date.distantPast) > ($1.pubDate ?? Date.distantPast)
            })
        }
    }

    //XML'de bir etiket başlarsa
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            //Yeni haber öğesi başlarken değerleri sıfırla
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }

    //Etiket içeriği okunursa
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        case "pubDate": currentPubDate += string
        default: break
        }
    }

    //Etiket kapanınca
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            var imageUrl: String? = nil

            //Açıklama içinde img varsa görseli çek
            if let range = currentDescription.range(of: "img src=\"") {
                let start = currentDescription[range.upperBound...]
                if let endRange = start.range(of: "\"") {
                    imageUrl = String(start[..<endRange.lowerBound])
                }
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z" //Örnek: "Wed, 01 May 2024 18:00:00 GMT"
            formatter.locale = Locale(identifier: "en_US_POSIX") //RSS formatları İngilizce olduğu için bu şart

            let parsedDate = formatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))

            let item = RSSFeedItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: imageUrl,
                pubDate: parsedDate
            )

            items.append(item)
        }
    }

    //Tüm belge bittiğinde
    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(items)
    }
}
