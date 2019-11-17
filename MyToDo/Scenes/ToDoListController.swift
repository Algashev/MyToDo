/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RealmSwift

class ToDoListController: UITableViewController {

  private var items: Results<ToDoItem>?
  private var itemsToken: NotificationToken?

  // MARK: - ViewController life-cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.items = ToDoItem.all()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.itemsToken = self.items?.observe({ [weak tableView] changes in
      guard let tableView = tableView else { return }
      switch changes {
      case .initial:
        tableView.reloadData()
      case .update(_, deletions: let deletions, insertions: let insertions, modifications: let modifications):
        tableView.applyChanges(deletions: deletions, insertions: insertions, updates: modifications)
      case .error: break
      }
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.itemsToken?.invalidate()
  }

  // MARK: - Actions

  @IBAction func addItem() {
    userInputAlert("Add Todo Item") { text in
      ToDoItem.add(text: text)
    }
  }
  
  private func toggleItem(_ item: ToDoItem) {
    item.toggleCompleted()
  }
  
  private func deleteItem(_ item: ToDoItem) {
    item.delete()
  }
}

// MARK: - Table View Data Source

extension ToDoListController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard
      let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? ToDoTableViewCell,
      let item = items?[indexPath.row]
    else {
      return ToDoTableViewCell(frame: .zero)
    }

    cell.configureWith(item) { [weak self] item in
      self?.toggleItem(item)
    }

    return cell
  }
}

// MARK: - Table View Delegate

extension ToDoListController {
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    guard
      let item = items?[indexPath.row],
      item.isCompleted,
      editingStyle == .delete
    else { return }

    self.deleteItem(item)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let item = items?[indexPath.row]
    else { return }
    userInputAlert("Edit Todo Item", text: item.text) { text in
      item.update(text: text)
    }
  }
}
