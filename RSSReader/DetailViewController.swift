import UIKit

class DetailViewController: UIViewController {

    var newsTitle: String?
    var newsDescription: String?
    var newsLink: String?
    var newsImageUrl: String?
    var newsDate: Date?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = newsTitle
        descriptionTextView.text = newsDescription?.htmlToPlainText() //HTML açıklamasını temizle
        
        if let date = newsDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = "-"
        }


        //Görseli URL'den indir
        if let imageUrl = newsImageUrl, let url = URL(string: imageUrl) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.newsImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }

    //Haberin web sitesini aç
    @IBAction func openLinkTapped(_ sender: UIButton) {
        if let link = newsLink, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
