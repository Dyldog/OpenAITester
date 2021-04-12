//
//  ViewController.swift
//  OpenAITester
//
//  Created by Dylan Elliott on 12/4/21.
//

import UIKit

struct OpenAIResponse: Codable {
    struct Choice: Codable {
        let text: String
    }
    
    let choices: [Choice]
}

class ViewController: UIViewController {
    
    @IBOutlet var inputTextView: UITextView!
    @IBOutlet var numTokensStepper: UIStepper!
    @IBOutlet var numTokensLabel: UILabel!
    
    @IBOutlet var outputTextView: UITextView!
    
    var inputText: String { return inputTextView.text ?? "" }
    var numTokens: Int { Int(numTokensStepper.value) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputTextView.text = """
        Q: What is 1 + 1?
        A: 2
        ###
        Q: What is 2 + 2?
        """
        numTokensStepper.value = 10
        numTokensStepperDidChange()
    }

    @IBAction func numTokensStepperDidChange() {
        numTokensLabel.text = "\(numTokens)"
    }
    
    func sanitiseInput(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    @IBAction func sendButtonTapped() {
        view.endEditing(true)
        outputTextView.text = "Loading..."
        
        let body = "{\"prompt\": \"\(sanitiseInput(inputText))\", \"max_tokens\": \(numTokens)}"
        let apiKey = Secrets.apiKey
        
        let request = NSMutableURLRequest(url: URL(string: "https://api.openai.com/v1/engines/davinci/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                self.showError(error)
                return
            } else {
                guard let data = data else {
                    self.showAlert(title: "Error", message: "No data or error returned")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                    self.setOutput(response.choices.first?.text ?? "NO CHOICE RETURNED")
                } catch {
                    let dataString = String(data: data, encoding: .utf8)
                    self.showError(error, supplementaryText: dataString)
                }
            }
        }.resume()
    }
    
    func setOutput(_ string: String) {
        DispatchQueue.main.async {
            self.outputTextView.text = string
        }
    }

    func showError(_ error: Error, supplementaryText: String? = nil) {
        let body = [error.localizedDescription, supplementaryText].compactMap { $0 }.joined(separator: "\n")
        showAlert(title: "Error", message: body)
    }
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

