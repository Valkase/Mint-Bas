# Flutter Recovery Booklet
## A Complete Guide to Reactivating Your Flutter Knowledge

---

# Phase 1: Core Flutter Foundations

## Chapter 1: Dart Essentials Refresher

### 1.1 Variable Modifiers: `late`, `final`, `const`

**Concept:**
- `final`: Runtime constant - value assigned once, can be computed at runtime
- `const`: Compile-time constant - value must be known at compile time
- `late`: Deferred initialization - variable will be initialized before use

**Example:**

```dart
// final - runtime constant
final String userName = getUserNameFromDatabase(); // OK
final DateTime now = DateTime.now(); // OK

// const - compile-time constant
const String appName = 'MyApp'; // OK
const int maxUsers = 100; // OK
// const DateTime now = DateTime.now(); // ERROR - not compile-time

// late - lazy initialization
late String expensiveData;

void initializeData() {
  expensiveData = loadHeavyData(); // Initialized when needed
}

// late final - combines both
late final String config = loadConfiguration();
```

**When to use:**
- `const`: For truly constant values (colors, strings, numbers)
- `final`: For values that don't change after initialization but need runtime computation
- `late`: When you know a variable will be initialized later, avoiding nullable types

### 1.2 Null Safety

**Concept:**
Dart's null safety prevents null reference errors at compile time.
- `?` - makes a variable nullable
- `!` - asserts a variable is not null (use carefully)
- `??` - null-aware operator (provides default value)
- `?.` - null-aware access

**Example:**

```dart
// Nullable vs Non-nullable
String nonNullable = 'Hello'; // Cannot be null
String? nullable; // Can be null

// Null-aware operators
String? userName;
String displayName = userName ?? 'Guest'; // Use 'Guest' if null

// Null-aware access
int? length = userName?.length; // Safe - returns null if userName is null

// Null assertion (dangerous - use only when certain)
String definitelyNotNull = userName!; // Throws if null

// Practical example
class User {
  final String name;
  final String? email; // Optional
  
  User(this.name, [this.email]);
  
  String getContactInfo() {
    return email ?? 'No email provided';
  }
}

void main() {
  User user1 = User('Alice', 'alice@example.com');
  User user2 = User('Bob');
  
  print(user1.getContactInfo()); // alice@example.com
  print(user2.getContactInfo()); // No email provided
}
```

### 1.3 Futures & Async/Await

**Concept:**
Handle asynchronous operations cleanly. A `Future` represents a value that will be available later.

**Example:**

```dart
// Basic Future
Future<String> fetchUserData() async {
  // Simulate network delay
  await Future.delayed(Duration(seconds: 2));
  return 'User data loaded';
}

// Using async/await
Future<void> displayUserData() async {
  print('Loading...');
  String data = await fetchUserData();
  print(data);
}

// Error handling
Future<String> fetchWithErrorHandling() async {
  try {
    final response = await fetchUserData();
    return response;
  } catch (e) {
    return 'Error: $e';
  }
}

// Multiple futures
Future<void> loadMultipleResources() async {
  // Sequential
  String user = await fetchUserData();
  String settings = await fetchSettings();
  
  // Parallel (faster)
  final results = await Future.wait([
    fetchUserData(),
    fetchSettings(),
  ]);
}

// Practical Flutter example
Future<List<String>> fetchItems() async {
  await Future.delayed(Duration(seconds: 1));
  return ['Item 1', 'Item 2', 'Item 3'];
}
```

---

## Chapter 2: Flutter App Structure

### 2.1 The Entry Point: `main()` and `runApp()`

**Concept:**
Every Flutter app starts with `main()` which calls `runApp()` to inflate the root widget.

**Example:**

```dart
import 'package:flutter/material.dart';

void main() {
  // Optional: Initialize services before app starts
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Recovery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Hello Flutter!')),
    );
  }
}
```

### 2.2 MaterialApp vs CupertinoApp

**Concept:**
- `MaterialApp`: Material Design (Android-style)
- `CupertinoApp`: iOS-style design

**Example:**

```dart
// Material Design
class MaterialExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Material Design')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {},
            child: Text('Material Button'),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

// iOS Design
import 'package:flutter/cupertino.dart';

class CupertinoExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('iOS Design'),
        ),
        child: Center(
          child: CupertinoButton(
            onPressed: () {},
            child: Text('Cupertino Button'),
          ),
        ),
      ),
    );
  }
}
```

---

## Chapter 3: Widgets & UI Fundamentals

### 3.1 StatelessWidget vs StatefulWidget

**Concept:**
- **StatelessWidget**: Immutable, doesn't change over time
- **StatefulWidget**: Mutable, has state that can change

**Example:**

```dart
// StatelessWidget - for static content
class WelcomeScreen extends StatelessWidget {
  final String userName;
  
  WelcomeScreen({required this.userName});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: Center(
        child: Text('Hello, $userName!'),
      ),
    );
  }
}

// StatefulWidget - for dynamic content
class CounterWidget extends StatefulWidget {
  @override
  _CounterWidgetState createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;
  
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('You have pressed the button:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

**When to use:**
- StatelessWidget: Profile displays, static pages, pure UI components
- StatefulWidget: Forms, counters, anything that changes based on user interaction

### 3.2 Common Layout Widgets

**Concept:**
Flutter uses a composition-based approach. Everything is a widget.

**Example - Column & Row:**

```dart
class LayoutExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Layout Examples')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row example
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.star, size: 50),
              Icon(Icons.favorite, size: 50),
              Icon(Icons.thumb_up, size: 50),
            ],
          ),
          
          // Container with styling
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Styled Container',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          
          // Padding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Text with padding'),
          ),
          
          // SizedBox for spacing
          SizedBox(height: 20),
          
          Text('After spacing'),
        ],
      ),
    );
  }
}
```

**Example - Stack:**

```dart
class StackExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stack Example')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background
            Container(
              width: 200,
              height: 200,
              color: Colors.blue,
            ),
            // Middle layer
            Container(
              width: 150,
              height: 150,
              color: Colors.red,
            ),
            // Top layer
            Text(
              'Stacked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3.3 ListView & GridView

**Concept:**
Display scrollable lists and grids of items.

**Example - ListView:**

```dart
class ListViewExample extends StatelessWidget {
  final List<String> items = List.generate(20, (index) => 'Item $index');
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ListView Example')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(items[index]),
            subtitle: Text('Subtitle for item $index'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              print('Tapped on ${items[index]}');
            },
          );
        },
      ),
    );
  }
}
```

**Example - GridView:**

```dart
class GridViewExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GridView Example')),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columns
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1, // Square items
        ),
        padding: EdgeInsets.all(10),
        itemCount: 20,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.primaries[index % Colors.primaries.length],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Item $index',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 3.4 Expanded & Flexible

**Concept:**
Control how children of Row/Column fill available space.

**Example:**

```dart
class ExpandedFlexibleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expanded & Flexible')),
      body: Column(
        children: [
          // Example 1: Expanded
          Container(
            height: 100,
            color: Colors.grey[300],
            child: Row(
              children: [
                Container(
                  width: 100,
                  color: Colors.red,
                  child: Center(child: Text('Fixed')),
                ),
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    child: Center(child: Text('Expanded')),
                  ),
                ),
                Container(
                  width: 100,
                  color: Colors.green,
                  child: Center(child: Text('Fixed')),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Example 2: Flex factors
          Container(
            height: 100,
            color: Colors.grey[300],
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.orange,
                    child: Center(child: Text('Flex 1')),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.purple,
                    child: Center(child: Text('Flex 2')),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.teal,
                    child: Center(child: Text('Flex 1')),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Example 3: Flexible vs Expanded
          Container(
            height: 100,
            color: Colors.grey[300],
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    color: Colors.red,
                    child: Center(child: Text('Flexible - can be smaller')),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.blue,
                    child: Center(child: Text('Expanded - must fill')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**When to use:**
- `Expanded`: When you want a widget to fill all available space
- `Flexible`: When you want a widget to take available space but can be smaller than that if content is smaller

---

# Phase 2: State & Navigation

## Chapter 4: State Management Basics

### 4.1 setState() - Local State

**Concept:**
`setState()` tells Flutter to rebuild the widget with updated state.

**Example:**

```dart
class TodoList extends StatefulWidget {
  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<String> _todos = [];
  final TextEditingController _controller = TextEditingController();
  
  void _addTodo() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _todos.add(_controller.text);
        _controller.clear();
      });
    }
  }
  
  void _removeTodo(int index) {
    setState(() {
      _todos.removeAt(index);
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todo List')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter todo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_todos[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _removeTodo(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4.2 Lifting State Up

**Concept:**
When multiple widgets need to share state, move it to their common parent.

**Example:**

```dart
// Parent widget holds the state
class ShoppingCart extends StatefulWidget {
  @override
  _ShoppingCartState createState() => _ShoppingCartState();
}

class _ShoppingCartState extends State<ShoppingCart> {
  List<String> _cartItems = [];
  
  void _addToCart(String item) {
    setState(() {
      _cartItems.add(item);
    });
  }
  
  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Child 1: Product list
        Expanded(
          child: ProductList(onAddToCart: _addToCart),
        ),
        
        // Child 2: Cart summary
        CartSummary(
          items: _cartItems,
          onRemove: _removeFromCart,
        ),
      ],
    );
  }
}

// Child 1: Receives callback to modify parent state
class ProductList extends StatelessWidget {
  final Function(String) onAddToCart;
  
  ProductList({required this.onAddToCart});
  
  final List<String> products = ['Apple', 'Banana', 'Orange', 'Grapes'];
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(products[index]),
          trailing: IconButton(
            icon: Icon(Icons.add_shopping_cart),
            onPressed: () => onAddToCart(products[index]),
          ),
        );
      },
    );
  }
}

// Child 2: Receives state from parent
class CartSummary extends StatelessWidget {
  final List<String> items;
  final Function(int) onRemove;
  
  CartSummary({required this.items, required this.onRemove});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cart (${items.length} items)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.value),
                IconButton(
                  icon: Icon(Icons.remove_circle),
                  onPressed: () => onRemove(entry.key),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
```

---

## Chapter 5: Navigation

### 5.1 Basic Navigation

**Concept:**
Navigate between screens using Navigator.push and pop.

**Example:**

```dart
// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to details screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsScreen()),
            );
          },
          child: Text('Go to Details'),
        ),
      ),
    );
  }
}

// Details Screen
class DetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Go back
            Navigator.pop(context);
          },
          child: Text('Go Back'),
        ),
      ),
    );
  }
}
```

### 5.2 Named Routes

**Concept:**
Define routes in MaterialApp for cleaner navigation.

**Example:**

```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Named Routes Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/details': (context) => DetailsScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/details');
              },
              child: Text('Go to Details'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              child: Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.3 Passing Arguments

**Concept:**
Pass data between screens during navigation.

**Example:**

```dart
// Data model
class Product {
  final String name;
  final double price;
  final String description;
  
  Product({
    required this.name,
    required this.price,
    required this.description,
  });
}

// Product List Screen
class ProductListScreen extends StatelessWidget {
  final List<Product> products = [
    Product(name: 'Laptop', price: 999.99, description: 'High-performance laptop'),
    Product(name: 'Phone', price: 699.99, description: 'Latest smartphone'),
    Product(name: 'Tablet', price: 399.99, description: 'Portable tablet'),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price}'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              // Pass product to details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Product Details Screen
class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  
  ProductDetailsScreen({required this.product});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'This is a card',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Theme automatically applies',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {},
              child: Text('Themed Button'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 13.2 Custom Theme with Provider

**Example:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyThemedApp(),
    ),
  );
}

class MyThemedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: HomeScreen(),
        );
      },
    );
  }
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.orange,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Color(0xFF121212),
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.orange,
    ),
  );
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Provider'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode 
                  ? Icons.light_mode 
                  : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
```

### 13.3 Responsive Design with MediaQuery

**Concept:**
Adapt your UI to different screen sizes and orientations.

**Example:**

```dart
class ResponsiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final orientation = MediaQuery.of(context).orientation;
    
    // Determine device type
    bool isMobile = width < 600;
    bool isTablet = width >= 600 && width < 900;
    bool isDesktop = width >= 900;
    
    return Scaffold(
      appBar: AppBar(title: Text('Responsive Design')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Screen width: ${width.toStringAsFixed(0)}'),
            Text('Screen height: ${height.toStringAsFixed(0)}'),
            Text('Orientation: $orientation'),
            Text('Device: ${isMobile ? "Mobile" : isTablet ? "Tablet" : "Desktop"}'),
            SizedBox(height: 20),
            
            // Responsive grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : isTablet ? 3 : 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.primaries[index % Colors.primaries.length],
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Responsive Layout Builder
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

// Usage example
class MyResponsiveApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: MobileLayout(),
        tablet: TabletLayout(),
        desktop: DesktopLayout(),
      ),
    );
  }
}

class MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Mobile Layout', style: TextStyle(fontSize: 24)),
        // Mobile-specific UI
      ],
    );
  }
}

class TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(color: Colors.blue[100]),
        ),
        Expanded(
          flex: 2,
          child: Text('Tablet Layout'),
        ),
      ],
    );
  }
}

class DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 200, color: Colors.blue[100]),
        Expanded(child: Text('Desktop Layout')),
        Container(width: 200, color: Colors.grey[200]),
      ],
    );
  }
}
```

---

# Phase 5: Production-Ready Flutter

## Chapter 14: Complete Mini Project

### Full-Featured Todo App with Provider, Local Storage, and Theming

**Example:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Models
class Todo {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime createdAt;
  
  Todo({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    isCompleted: json['isCompleted'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// Services
class StorageService {
  static const String _todosKey = 'todos';
  
  Future<List<Todo>> loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosJson = prefs.getString(_todosKey);
    
    if (todosJson == null) return [];
    
    List<dynamic> decoded = jsonDecode(todosJson);
    return decoded.map((json) => Todo.fromJson(json)).toList();
  }
  
  Future<void> saveTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      todos.map((todo) => todo.toJson()).toList(),
    );
    await prefs.setString(_todosKey, encoded);
  }
}

// Providers
class TodoProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Todo> _todos = [];
  bool _isLoading = false;
  
  List<Todo> get todos => [..._todos];
  List<Todo> get completedTodos => _todos.where((t) => t.isCompleted).toList();
  List<Todo> get pendingTodos => _todos.where((t) => !t.isCompleted).toList();
  bool get isLoading => _isLoading;
  
  TodoProvider() {
    loadTodos();
  }
  
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();
    
    _todos = await _storageService.loadTodos();
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> addTodo(String title, String description) async {
    final todo = Todo(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );
    
    _todos.add(todo);
    await _storageService.saveTodos(_todos);
    notifyListeners();
  }
  
  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      await _storageService.saveTodos(_todos);
      notifyListeners();
    }
  }
  
  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((t) => t.id == id);
    await _storageService.saveTodos(_todos);
    notifyListeners();
  }
  
  Future<void> updateTodo(String id, String title, String description) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index].title = title;
      _todos[index].description = description;
      await _storageService.saveTodos(_todos);
      notifyListeners();
    }
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }
}

// Main App
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: TodoApp(),
    ),
  );
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Todo App',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[100],
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Color(0xFF121212),
          ),
          home: TodoListScreen(),
        );
      },
    );
  }
}

// Screens
class TodoListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Todos'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                );
              },
            ),
          ],
        ),
        body: Consumer<TodoProvider>(
          builder: (context, todoProvider, child) {
            if (todoProvider.isLoading) {
              return Center(child: CircularProgressIndicator());
            }
            
            return TabBarView(
              children: [
                TodoListView(todos: todoProvider.todos),
                TodoListView(todos: todoProvider.pendingTodos),
                TodoListView(todos: todoProvider.completedTodos),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTodoScreen()),
            );
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class TodoListView extends StatelessWidget {
  final List<Todo> todos;
  
  TodoListView({required this.todos});
  
  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('No todos yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoCard(todo: todo);
      },
    );
  }
}

class TodoCard extends StatelessWidget {
  final Todo todo;
  
  TodoCard({required this.todo});
  
  @override
  Widget build(BuildContext context) {
    final todoProvider = context.read<TodoProvider>();
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => todoProvider.toggleTodo(todo.id),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted 
                ? TextDecoration.lineThrough 
                : null,
          ),
        ),
        subtitle: Text(
          todo.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTodoScreen(todo: todo),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete Todo'),
                    content: Text('Are you sure you want to delete this todo?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  todoProvider.deleteTodo(todo.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AddTodoScreen extends StatefulWidget {
  @override
  _AddTodoScreenState createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      context.read<TodoProvider>().addTodo(
        _titleController.text,
        _descriptionController.text,
      );
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Todo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _saveTodo,
                child: Text('Save Todo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditTodoScreen extends StatefulWidget {
  final Todo todo;
  
  EditTodoScreen({required this.todo});
  
  @override
  _EditTodoScreenState createState() => _EditTodoScreenState();
}

class _EditTodoScreenState extends State<EditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _updateTodo() {
    if (_formKey.currentState!.validate()) {
      context.read<TodoProvider>().updateTodo(
        widget.todo.id,
        _titleController.text,
        _descriptionController.text,
      );
      Navigator.pop(context);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Todo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _updateTodo,
                child: Text('Update Todo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Chapter 15: Best Practices & Tips

### 15.1 Code Organization Checklist

✅ **Project Structure**
- Separate models, services, providers, screens, widgets
- Keep widgets small and focused
- Extract reusable widgets

✅ **State Management**
- Use Provider for global state
- Use setState for local, simple state
- Don't overuse global state

✅ **Performance**
- Use const constructors when possible
- Avoid rebuilding entire screens
- Use keys when needed
- Dispose controllers and streams

✅ **Async Operations**
- Always handle errors
- Show loading states
- Use FutureBuilder/StreamBuilder appropriately

✅ **Forms**
- Always validate input
- Dispose TextEditingControllers
- Use Form widget for complex forms

✅ **Storage**
- Abstract storage into service classes
- Handle storage errors gracefully
- Don't store sensitive data in SharedPreferences

### 15.2 Common Pitfalls to Avoid

**❌ Don't:**
```dart
// Calling setState in build
@override
Widget build(BuildContext context) {
  setState(() {}); // WRONG!
  return Container();
}

// Not disposing controllers
class BadWidget extends StatefulWidget {
  final controller = TextEditingController(); // WRONG - memory leak
}

// Using context after async gap without checking mounted
Future<void> badAsyncMethod() async {
  await Future.delayed(Duration(seconds: 1));
  Navigator.pop(context); // WRONG - widget might be disposed
}
```

**✅ Do:**
```dart
// Use initState for initialization
@override
void initState() {
  super.initState();
  _loadData();
}

// Always dispose
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// Check mounted before using context
Future<void> goodAsyncMethod() async {
  await Future.delayed(Duration(seconds: 1));
  if (mounted) {
    Navigator.pop(context); // Safe
  }
}
```

---

## Conclusion

### Your Flutter Recovery Roadmap

**Week 1: Core Foundations**
- ✅ Dart refresher (late, final, const, null safety, async/await)
- ✅ Widgets (Stateless/Stateful, layouts)
- ✅ Navigation basics
- 🎯 Project: Simple 3-screen app

**Week 2: State & Data**
- ✅ Provider setup
- ✅ FutureBuilder & StreamBuilder
- ✅ HTTP requests
- 🎯 Project: API-based list app

**Week 3: Polish & Architecture**
- ✅ Forms & validation
- ✅ App structure
- ✅ Animations
- 🎯 Project: Todo app with storage

**Week 4: Production Ready**
- ✅ Theming
- ✅ Responsive design
- ✅ Performance optimization
- 🎯 Project: Complete production app

### Next Steps

1. **Start coding immediately** - Don't just read, build!
2. **Follow the order** - Each chapter builds on previous knowledge
3. **Complete the mini-projects** - They reinforce concepts
4. **Experiment** - Modify the examples to understand deeply

### Additional Resources

- Official Flutter docs: flutter.dev
- Dart language tour: dart.dev
- Flutter widget catalog: flutter.dev/widgets
- Pub.dev for packages: pub.dev

**Remember**: You're not learning from scratch—you're **reactivating** knowledge. It will come back faster than you think! 🚀

---

*End of Flutter Recovery Booklet*
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '\$${product.price}',
              style: TextStyle(fontSize: 20, color: Colors.green),
            ),
            SizedBox(height: 20),
            Text(
              product.description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Products'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Using Named Routes with Arguments:**

```dart
// In MaterialApp
onGenerateRoute: (settings) {
  if (settings.name == '/details') {
    final product = settings.arguments as Product;
    return MaterialPageRoute(
      builder: (context) => ProductDetailsScreen(product: product),
    );
  }
  return null;
}

// Navigate with arguments
Navigator.pushNamed(
  context,
  '/details',
  arguments: product,
);
```

---

# Phase 3: Intermediate Flutter

## Chapter 6: State Management with Provider

### 6.1 Why Provider?

**Concept:**
Provider solves the problem of prop drilling and allows widgets deep in the tree to access state without passing it through every level.

**Setup:**

Add to `pubspec.yaml`:
```yaml
dependencies:
  provider: ^6.0.0
```

### 6.2 Basic Provider Example

**Example:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Create a ChangeNotifier class
class Counter extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners(); // Tells widgets to rebuild
  }
  
  void decrement() {
    _count--;
    notifyListeners();
  }
  
  void reset() {
    _count = 0;
    notifyListeners();
  }
}

// 2. Provide it at the top of the widget tree
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Counter(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterScreen(),
    );
  }
}

// 3. Consume it anywhere in the tree
class CounterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Provider Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count:'),
            // Consumer rebuilds only this part
            Consumer<Counter>(
              builder: (context, counter, child) {
                return Text(
                  '${counter.count}',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                );
              },
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Access counter methods
                    context.read<Counter>().decrement();
                  },
                  child: Text('-'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<Counter>().increment();
                  },
                  child: Text('+'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<Counter>().reset();
                  },
                  child: Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.3 Real-World Provider Example: Shopping Cart

**Example:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Models
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

// State management
class CartProvider extends ChangeNotifier {
  Map<String, CartItem> _items = {};
  
  Map<String, CartItem> get items => {..._items};
  
  int get itemCount => _items.length;
  
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, item) {
      total += item.price * item.quantity;
    });
    return total;
  }
  
  void addItem(String productId, String name, double price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(id: productId, name: name, price: price),
      );
    }
    notifyListeners();
  }
  
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }
  
  void clear() {
    _items = {};
    notifyListeners();
  }
}

// Main App
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductsScreen(),
    );
  }
}

// Products Screen
class ProductsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products = [
    {'id': '1', 'name': 'Laptop', 'price': 999.99},
    {'id': '2', 'name': 'Phone', 'price': 699.99},
    {'id': '3', 'name': 'Headphones', 'price': 199.99},
    {'id': '4', 'name': 'Tablet', 'price': 499.99},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
          // Cart icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return cart.itemCount == 0
                        ? SizedBox.shrink()
                        : Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text('\${product['price']}'),
            trailing: IconButton(
              icon: Icon(Icons.add_shopping_cart),
              onPressed: () {
                context.read<CartProvider>().addItem(
                      product['id'],
                      product['name'],
                      product['price'],
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added to cart!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Cart Screen
class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    
    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: cart.itemCount == 0
          ? Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items.values.toList()[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('\${item.price} x ${item.quantity}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            cart.removeItem(item.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\${cart.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
```

**Key Provider Concepts:**
- `context.read<T>()`: Access provider without rebuilding (for methods/actions)
- `context.watch<T>()`: Access provider and rebuild when it changes
- `Consumer<T>`: Rebuild only a specific widget subtree
- `notifyListeners()`: Trigger rebuild of all listening widgets

---

## Chapter 7: Async & Data Handling

### 7.1 FutureBuilder

**Concept:**
FutureBuilder automatically rebuilds the UI based on the state of a Future (loading, success, error).

**Example:**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  final int id;
  final String name;
  final String email;
  
  User({required this.id, required this.name, required this.email});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class UserService {
  Future<List<User>> fetchUsers() async {
    final response = await http.get(
      Uri.parse('https://jsonplaceholder.typicode.com/users'),
    );
    
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
}

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  late Future<List<User>> _usersFuture;
  
  @override
  void initState() {
    super.initState();
    _usersFuture = _userService.fetchUsers();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _usersFuture = _userService.fetchUsers();
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          // Success state
          if (snapshot.hasData) {
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(user.id.toString())),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                );
              },
            );
          }
          
          // Empty state
          return Center(child: Text('No data'));
        },
      ),
    );
  }
}
```

### 7.2 StreamBuilder

**Concept:**
StreamBuilder listens to a Stream and rebuilds when new data arrives. Perfect for real-time data.

**Example:**

```dart
import 'dart:async';

// Simulated real-time data service
class StockService {
  Stream<double> getStockPriceStream() async* {
    double price = 100.0;
    while (true) {
      await Future.delayed(Duration(seconds: 2));
      // Simulate price changes
      price += (Random().nextDouble() - 0.5) * 5;
      yield price;
    }
  }
}

class StockPriceScreen extends StatelessWidget {
  final StockService _stockService = StockService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Stock Price')),
      body: Center(
        child: StreamBuilder<double>(
          stream: _stockService.getStockPriceStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            
            if (snapshot.hasData) {
              final price = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Current Price',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            }
            
            return Text('No data');
          },
        ),
      ),
    );
  }
}

// Real-world example: Chat messages
class Message {
  final String sender;
  final String text;
  final DateTime timestamp;
  
  Message({required this.sender, required this.text, required this.timestamp});
}

class ChatService {
  final _messageController = StreamController<Message>.broadcast();
  
  Stream<Message> get messageStream => _messageController.stream;
  
  void sendMessage(String sender, String text) {
    final message = Message(
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
    );
    _messageController.add(message);
  }
  
  void dispose() {
    _messageController.close();
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  
  @override
  void dispose() {
    _chatService.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _chatService.sendMessage('You', _controller.text);
      _controller.clear();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Message>(
              stream: _chatService.messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _messages.add(snapshot.data!);
                }
                
                return ListView.builder(
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return ListTile(
                      title: Text(message.sender),
                      subtitle: Text(message.text),
                      trailing: Text(
                        '${message.timestamp.hour}:${message.timestamp.minute}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 7.3 HTTP Requests with Error Handling

**Concept:**
Make API calls with proper error handling and loading states.

**Setup:**
```yaml
dependencies:
  http: ^1.1.0
```

**Example:**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// Model
class Post {
  final int id;
  final String title;
  final String body;
  
  Post({required this.id, required this.title, required this.body});
  
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
    };
  }
}

// API Service
class ApiService {
  final String baseUrl = 'https://jsonplaceholder.typicode.com';
  
  // GET request
  Future<List<Post>> getPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts'),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // POST request
  Future<Post> createPost(Post post) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(post.toJson()),
      );
      
      if (response.statusCode == 201) {
        return Post.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }
  
  // PUT request
  Future<Post> updatePost(int id, Post post) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(post.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Post.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update post');
    }
  }
  
  // DELETE request
  Future<void> deletePost(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$id'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete post');
    }
  }
}

// Screen with full CRUD operations
class PostsScreen extends StatefulWidget {
  @override
  _PostsScreenState createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Post>> _postsFuture;
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
  }
  
  void _loadPosts() {
    setState(() {
      _postsFuture = _apiService.getPosts();
    });
  }
  
  Future<void> _createPost() async {
    final newPost = Post(id: 0, title: 'New Post', body: 'This is a new post');
    try {
      await _apiService.createPost(newPost);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created successfully')),
      );
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Posts')),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPosts,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.hasData) {
            final posts = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _loadPosts();
              },
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(post.title),
                      subtitle: Text(
                        post.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await _apiService.deletePost(post.id);
                            _loadPosts();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting: $e')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          }
          
          return Center(child: Text('No data'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## Chapter 8: App Architecture

### 8.1 Folder Structure

**Concept:**
Organize your code for maintainability and scalability.

**Recommended Structure:**

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   ├── product.dart
│   └── order.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── cart_provider.dart
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── home_card.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   ├── custom_button.dart
│   └── loading_indicator.dart
└── utils/
    ├── constants.dart
    └── helpers.dart
```

### 8.2 Separation of Concerns Example

**Example:**

```dart
// models/product.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}

// services/product_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductService {
  final String baseUrl = 'https://api.example.com';
  
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
  
  Future<Product> getProductById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));
    
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Product not found');
    }
  }
}

// providers/product_provider.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  
  List<Product> get products => [..._products];
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _products = await _productService.fetchProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Product? findById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}

// screens/products/products_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import 'widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when screen initializes
    Future.microtask(
      () => context.read<ProductProvider>().loadProducts(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${productProvider.error}'),
                  ElevatedButton(
                    onPressed: () => productProvider.loadProducts(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final products = productProvider.products;
          
          if (products.isEmpty) {
            return Center(child: Text('No products found'));
          }
          
          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}

// screens/products/widgets/product_card.dart
import 'package:flutter/material.dart';
import '../../../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  
  ProductCard({required this.product});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '\${product.price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// utils/constants.dart
class AppConstants {
  static const String appName = 'My Store';
  static const String apiBaseUrl = 'https://api.example.com';
  static const Duration requestTimeout = Duration(seconds: 10);
}

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
}
```

---

## Chapter 9: Forms & Input

### 9.1 TextEditingController

**Concept:**
Control and read text input values.

**Example:**

```dart
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Listen to changes
    _emailController.addListener(() {
      print('Email: ${_emailController.text}');
    });
  }
  
  @override
  void dispose() {
    // Always dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _handleLogin() {
    final email = _emailController.text;
    final password = _passwordController.text;
    
    print('Login attempt: $email / $password');
    
    // Clear fields after submission
    _emailController.clear();
    _passwordController.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 9.2 Form & Validation

**Concept:**
Use Form widget with validation for robust form handling.

**Example:**

```dart
class RegistrationForm extends StatefulWidget {
  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _name;
  String? _email;
  String? _password;
  String? _confirmPassword;
  bool _agreedToTerms = false;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4});
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please agree to terms and conditions')),
        );
        return;
      }
      
      // Save form data
      _formKey.currentState!.save();
      
      print('Name: $_name');
      print('Email: $_email');
      print('Password: $_password');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                onSaved: (value) => _email = value,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: _validatePassword,
                onSaved: (value) => _password = value,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onSaved: (value) => _confirmPassword = value,
              ),
              SizedBox(height: 16),
              
              CheckboxListTile(
                title: Text('I agree to terms and conditions'),
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Register', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

# Phase 4: Advanced Topics

## Chapter 10: Widget Lifecycle & Performance

### 10.1 StatefulWidget Lifecycle

**Concept:**
Understanding the lifecycle helps you optimize performance and manage resources.

**Lifecycle Methods:**

```dart
class LifecycleDemo extends StatefulWidget {
  @override
  _LifecycleDemoState createState() {
    print('1. createState()');
    return _LifecycleDemoState();
  }
}

class _LifecycleDemoState extends State<LifecycleDemo> {
  int _counter = 0;
  
  // Called once when State object is created
  @override
  void initState() {
    super.initState();
    print('2. initState()');
    // Initialize data, start timers, subscribe to streams
    _loadInitialData();
  }
  
  // Called when widget configuration changes
  @override
  void didUpdateWidget(LifecycleDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('3. didUpdateWidget()');
    // Compare oldWidget with widget to handle changes
  }
  
  // Called when State object is removed permanently
  @override
  void dispose() {
    print('5. dispose()');
    // Clean up: cancel timers, close streams, dispose controllers
    super.dispose();
  }
  
  void _loadInitialData() {
    // Simulate loading data
    print('Loading initial data...');
  }
  
  @override
  Widget build(BuildContext context) {
    print('4. build()');
    return Scaffold(
      appBar: AppBar(title: Text('Lifecycle Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Counter: $_counter'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _counter++;
                });
              },
              child: Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Practical Example with Cleanup:**

```dart
class TimerWidget extends StatefulWidget {
  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  int _seconds = 0;
  
  @override
  void initState() {
    super.initState();
    // Start timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }
  
  @override
  void dispose() {
    // IMPORTANT: Cancel timer to prevent memory leaks
    _timer.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Timer')),
      body: Center(
        child: Text(
          'Elapsed: $_seconds seconds',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
```

### 10.2 Keys - When and Why

**Concept:**
Keys preserve state when widgets move in the tree or when you have lists of similar widgets.

**Example - Without Keys (Problem):**

```dart
class NoKeysExample extends StatefulWidget {
  @override
  _NoKeysExampleState createState() => _NoKeysExampleState();
}

class _NoKeysExampleState extends State<NoKeysExample> {
  List<ColorBox> boxes = [
    ColorBox(color: Colors.red),
    ColorBox(color: Colors.blue),
  ];
  
  void _swapBoxes() {
    setState(() {
      boxes.insert(0, boxes.removeAt(1));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Without Keys')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: boxes,
          ),
          ElevatedButton(
            onPressed: _swapBoxes,
            child: Text('Swap'),
          ),
        ],
      ),
    );
  }
}

class ColorBox extends StatefulWidget {
  final Color color;
  
  ColorBox({required this.color});
  
  @override
  _ColorBoxState createState() => _ColorBoxState();
}

class _ColorBoxState extends State<ColorBox> {
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _counter++;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        margin: EdgeInsets.all(8),
        color: widget.color,
        child: Center(
          child: Text(
            '$_counter',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    );
  }
}
```

**Example - With Keys (Solution):**

```dart
class WithKeysExample extends StatefulWidget {
  @override
  _WithKeysExampleState createState() => _WithKeysExampleState();
}

class _WithKeysExampleState extends State<WithKeysExample> {
  List<ColorBox> boxes = [
    ColorBox(key: ValueKey(1), color: Colors.red),
    ColorBox(key: ValueKey(2), color: Colors.blue),
  ];
  
  void _swapBoxes() {
    setState(() {
      boxes.insert(0, boxes.removeAt(1));
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('With Keys - State Preserved')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: boxes,
          ),
          ElevatedButton(
            onPressed: _swapBoxes,
            child: Text('Swap'),
          ),
        ],
      ),
    );
  }
}
```

**Types of Keys:**

```dart
// ValueKey - for simple values
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(
      key: ValueKey(items[index].id),
      title: Text(items[index].name),
    );
  },
);

// ObjectKey - for objects
ColorBox(key: ObjectKey(myObject), color: Colors.red);

// UniqueKey - generates unique key each time
ColorBox(key: UniqueKey(), color: Colors.red);

// GlobalKey - access widget state from anywhere (use sparingly)
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
Form(
  key: _formKey,
  child: // form fields
);
// Later: _formKey.currentState!.validate();
```

### 10.3 Build Optimization

**Concept:**
Minimize unnecessary rebuilds for better performance.

**Example:**

```dart
// BAD: Entire widget rebuilds
class UnoptimizedWidget extends StatefulWidget {
  @override
  _UnoptimizedWidgetState createState() => _UnoptimizedWidgetState();
}

class _UnoptimizedWidgetState extends State<UnoptimizedWidget> {
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    print('Entire widget rebuilds!');
    return Scaffold(
      appBar: AppBar(title: Text('Unoptimized')),
      body: Column(
        children: [
          // This rebuilds every time even though it doesn't change
          ExpensiveWidget(),
          Text('Counter: $_counter'),
          ElevatedButton(
            onPressed: () => setState(() => _counter++),
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class ExpensiveWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('ExpensiveWidget rebuilt unnecessarily!');
    return Container(
      height: 200,
      color: Colors.blue,
      child: Center(child: Text('I rebuild unnecessarily')),
    );
  }
}

// GOOD: Only counter rebuilds
class OptimizedWidget extends StatefulWidget {
  @override
  _OptimizedWidgetState createState() => _OptimizedWidgetState();
}

class _OptimizedWidgetState extends State<OptimizedWidget> {
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Optimized')),
      body: Column(
        children: [
          // Moved to separate widget - won't rebuild
          ExpensiveStaticWidget(),
          // Only this part rebuilds
          CounterDisplay(counter: _counter),
          ElevatedButton(
            onPressed: () => setState(() => _counter++),
            child: Text('Increment'),
          ),
        ],
      ),
    );
  }
}

class ExpensiveStaticWidget extends StatelessWidget {
  const ExpensiveStaticWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('ExpensiveStaticWidget built only once!');
    return Container(
      height: 200,
      color: Colors.blue,
      child: Center(child: Text('I only build once')),
    );
  }
}

class CounterDisplay extends StatelessWidget {
  final int counter;
  
  const CounterDisplay({Key? key, required this.counter}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('Only CounterDisplay rebuilds');
    return Text('Counter: $counter');
  }
}
```

**Using const Constructors:**

```dart
// const widgets don't rebuild at all
class ConstExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // This never rebuilds
        const Text('Static text'),
        const Icon(Icons.star),
        const SizedBox(height: 20),
        
        // This rebuilds when parent rebuilds
        Text('Dynamic: ${DateTime.now()}'),
      ],
    );
  }
}
```

---

## Chapter 11: Animations

### 11.1 Implicit Animations

**Concept:**
Simple animations that automatically animate between values.

**Example:**

```dart
class ImplicitAnimationsDemo extends StatefulWidget {
  @override
  _ImplicitAnimationsDemoState createState() => _ImplicitAnimationsDemoState();
}

class _ImplicitAnimationsDemoState extends State<ImplicitAnimationsDemo> {
  bool _expanded = false;
  double _opacity = 1.0;
  Color _color = Colors.blue;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Implicit Animations')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AnimatedContainer
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: _expanded ? 200 : 100,
              height: _expanded ? 200 : 100,
              color: _color,
              child: Center(
                child: Text(
                  'Tap me',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // AnimatedOpacity
            AnimatedOpacity(
              duration: Duration(milliseconds: 500),
              opacity: _opacity,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                  _opacity = _opacity == 1.0 ? 0.2 : 1.0;
                  _color = _color == Colors.blue ? Colors.green : Colors.blue;
                });
              },
              child: Text('Animate'),
            ),
          ],
        ),
      ),
    );
  }
}

// More implicit animations
class MoreImplicitAnimations extends StatefulWidget {
  @override
  _MoreImplicitAnimationsState createState() => _MoreImplicitAnimationsState();
}

class _MoreImplicitAnimationsState extends State<MoreImplicitAnimations> {
  bool _visible = true;
  double _padding = 8.0;
  AlignmentGeometry _alignment = Alignment.topLeft;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AnimatedCrossFade
          AnimatedCrossFade(
            duration: Duration(milliseconds: 300),
            firstChild: Icon(Icons.favorite_border, size: 100),
            secondChild: Icon(Icons.favorite, color: Colors.red, size: 100),
            crossFadeState: _visible
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
          ),
          
          // AnimatedPadding
          AnimatedPadding(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.all(_padding),
            child: Container(
              color: Colors.blue,
              width: 100,
              height: 100,
            ),
          ),
          
          // AnimatedAlign
          Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: AnimatedAlign(
              duration: Duration(milliseconds: 500),
              alignment: _alignment,
              child: Container(
                width: 50,
                height: 50,
                color: Colors.purple,
              ),
            ),
          ),
          
          ElevatedButton(
            onPressed: () {
              setState(() {
                _visible = !_visible;
                _padding = _padding == 8.0 ? 40.0 : 8.0;
                _alignment = _alignment == Alignment.topLeft
                    ? Alignment.bottomRight
                    : Alignment.topLeft;
              });
            },
            child: Text('Toggle'),
          ),
        ],
      ),
    );
  }
}
```

### 11.2 Explicit Animations with AnimationController

**Concept:**
More control over animations using AnimationController.

**Example:**

```dart
class ExplicitAnimationDemo extends StatefulWidget {
  @override
  _ExplicitAnimationDemoState createState() => _ExplicitAnimationDemoState();
}

class _ExplicitAnimationDemoState extends State<ExplicitAnimationDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Create controller
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    // Create animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      _controller,
    );
    
    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      _controller,
    );
    
    // Listen to animation status
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animation completed
        print('Animation completed');
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Explicit Animation')),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.star, color: Colors.white, size: 50),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _controller.forward(),
            child: Icon(Icons.play_arrow),
            heroTag: 'play',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () => _controller.reverse(),
            child: Icon(Icons.replay),
            heroTag: 'reverse',
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () => _controller.repeat(),
            child: Icon(Icons.loop),
            heroTag: 'repeat',
          ),
        ],
      ),
    );
  }
}
```

### 11.3 Hero Animations

**Concept:**
Smooth transitions of widgets between screens.

**Example:**

```dart
// List screen
class HeroListScreen extends StatelessWidget {
  final List<String> items = ['Item 1', 'Item 2', 'Item 3'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hero Animation')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Hero(
              tag: 'hero-$index',
              child: CircleAvatar(
                child: Text('${index + 1}'),
              ),
            ),
            title: Text(items[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeroDetailScreen(
                    heroTag: 'hero-$index',
                    title: items[index],
                    index: index + 1,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Detail screen
class HeroDetailScreen extends StatelessWidget {
  final String heroTag;
  final String title;
  final int index;
  
  HeroDetailScreen({
    required this.heroTag,
    required this.title,
    required this.index,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: CircleAvatar(
            radius: 100,
            child: Text(
              '$index',
              style: TextStyle(fontSize: 60),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Chapter 12: Local Storage

### 12.1 Shared Preferences

**Concept:**
Store simple key-value pairs persistently.

**Setup:**
```yaml
dependencies:
  shared_preferences: ^2.2.0
```

**Example:**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDemo extends StatefulWidget {
  @override
  _SharedPreferencesDemoState createState() => _SharedPreferencesDemoState();
}

class _SharedPreferencesDemoState extends State<SharedPreferencesDemo> {
  int _counter = 0;
  String _username = '';
  bool _darkMode = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt('counter') ?? 0;
      _username = prefs.getString('username') ?? '';
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
  }
  
  Future<void> _incrementCounter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter++;
    });
    await prefs.setInt('counter', _counter);
  }
  
  Future<void> _saveUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', value);
    setState(() {
      _username = value;
    });
  }
  
  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      _darkMode = value;
    });
  }
  
  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _counter = 0;
      _username = '';
      _darkMode = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SharedPreferences Demo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Counter: $_counter', style: TextStyle(fontSize: 24)),
            ElevatedButton(
              onPressed: _incrementCounter,
              child: Text('Increment Counter'),
            ),
            SizedBox(height: 20),
            
            TextField(
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _saveUsername,
            ),
            SizedBox(height: 10),
            Text('Saved username: $_username'),
            SizedBox(height: 20),
            
            SwitchListTile(
              title: Text('Dark Mode'),
              value: _darkMode,
              onChanged: _toggleDarkMode,
            ),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _clearAll,
              child: Text('Clear All Data'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// Storage service pattern
class StorageService {
  static const String _counterKey = 'counter';
  static const String _usernameKey = 'username';
  
  Future<int> getCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_counterKey) ?? 0;
  }
  
  Future<void> setCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_counterKey, value);
  }
  
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
  
  Future<void> setUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, value);
  }
}
```

---

## Chapter 13: Theming

### 13.1 Light & Dark Themes

**Concept:**
Create consistent app-wide styling with theme switching.

**Example:**

```dart
class ThemeDemo extends StatefulWidget {
  @override
  _ThemeDemoState createState() => _ThemeDemoState();
}

class _ThemeDemoState extends State<ThemeDemo> {
  bool _isDark = false;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: ThemeHomeScreen(
        isDark: _isDark,
        onThemeChanged: (value) {
          setState(() {
            _isDark = value;
          });
        },
      ),
    );
  }
}

class ThemeHomeScreen extends StatelessWidget {
  final bool isDark;
  final Function(bool) onThemeChanged;
  
  ThemeHomeScreen({required this.isDark, required this.onThemeChanged});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Demo'),
        actions: [
          Switch(
            value: isDark,
            onChanged: onThemeChanged,
            activeColor: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(