const path = require('path');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const mainPath = path.resolve(__dirname, 'app/assets/elm');
const assetPath = path.resolve(__dirname, 'app/assets/javascripts');

module.exports = {
    entry: {
        elm: (mainPath + "/index.js")
    },
    output: {
        filename: "elm_controls.js",
        path: assetPath
    },

    // Enable sourcemaps for debugging webpack's output.
    devtool: "source-map",

    resolve: {
        extensions: [".elm", ".js"],
        modules: [nodeModulesPath]
    },
    module: {
	    rules: [
	    {
		    test: /\.elm$/,
		    exclude: [/elm-stuff/, /node_modules/],
		    use: {
			    loader: ('elm-webpack-loader?verbose=true&warn=true&cwd=' + mainPath),
			    options: {
				    verbose: true,
				    warn: true
			    }
		    }
	    }
	    ]
    }
};
